#![forbid(unsafe_code)]
//! Host-owned File Tunnel picker state with an optional `egui` renderer.
//!
//! This crate deliberately owns no HTTP client, capability persistence,
//! analytics, logging, clipboard access, or background worker. Applications
//! keep the sensitive pairing URI and pass a short-lived borrowed view to the
//! renderer for the duration of one frame.

/// The same lifecycle rendered by the SwiftUI, Compose, Flutter, and web
/// packages in this repository.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PickerStage {
    Idle,
    Creating,
    Pairing,
    Transferring,
    Complete,
    Failed,
}

/// Sanitized progress for one host-owned file transfer.
///
/// The component renders `name`, so hosts must decide that showing it on the
/// current screen is appropriate. The component never logs or stores it.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct FileProgress {
    pub id: String,
    pub name: String,
    pub bytes_transferred: u64,
    pub size_bytes: u64,
    pub is_complete: bool,
}

impl FileProgress {
    /// Progress clamped to the inclusive `0.0..=1.0` range.
    pub fn fraction_completed(&self) -> f32 {
        if self.size_bytes == 0 {
            return if self.is_complete { 1.0 } else { 0.0 };
        }
        (self.bytes_transferred.min(self.size_bytes) as f64 / self.size_bytes as f64) as f32
    }

    pub fn percent_completed(&self) -> u8 {
        (self.fraction_completed() * 100.0).round() as u8
    }
}

/// Borrowed state for one render pass. Pairing material remains host-owned.
#[derive(Clone, Copy, Debug)]
pub struct PickerView<'a> {
    pub stage: PickerStage,
    pub pairing_uri: Option<&'a str>,
    pub expires_label: Option<&'a str>,
    pub files: &'a [FileProgress],
    /// A pre-redacted, user-actionable message. Never pass raw transport errors.
    pub failure_message: Option<&'a str>,
}

impl<'a> PickerView<'a> {
    pub const fn idle() -> Self {
        Self {
            stage: PickerStage::Idle,
            pairing_uri: None,
            expires_label: None,
            files: &[],
            failure_message: None,
        }
    }

    pub fn validate(&self) -> Result<(), ViewError> {
        match self.stage {
            PickerStage::Pairing | PickerStage::Transferring
                if self.pairing_uri.is_none_or(str::is_empty) =>
            {
                Err(ViewError::MissingPairingUri)
            }
            PickerStage::Failed if self.failure_message.is_none_or(str::is_empty) => {
                Err(ViewError::MissingFailureMessage)
            }
            _ => Ok(()),
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ViewError {
    MissingPairingUri,
    MissingFailureMessage,
}

/// An explicit host action emitted by a renderer. Rendering never performs it.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PickerAction {
    ChooseLocal,
    ChooseRemote,
    Cancel,
    Retry,
}

#[cfg(feature = "egui")]
pub mod egui_renderer {
    use egui::{Color32, Sense, Ui, Vec2};
    use qrcode::{Color, QrCode};

    use super::{FileProgress, PickerAction, PickerStage, PickerView};

    /// Render the shared picker state without retaining it or performing an
    /// action. The returned action is for the host to execute after rendering.
    pub fn render(ui: &mut Ui, view: PickerView<'_>) -> Option<PickerAction> {
        ui.heading("Add files");
        ui.add_space(12.0);

        match view.stage {
            PickerStage::Idle => render_choices(ui),
            PickerStage::Creating => {
                ui.horizontal(|ui| {
                    ui.spinner();
                    ui.label("Opening a secure tunnel…");
                });
                None
            }
            PickerStage::Pairing | PickerStage::Transferring => render_pairing(ui, view),
            PickerStage::Complete => {
                ui.colored_label(Color32::from_rgb(24, 130, 74), "Files received");
                None
            }
            PickerStage::Failed => {
                ui.colored_label(
                    ui.visuals().error_fg_color,
                    view.failure_message.unwrap_or("The tunnel is unavailable."),
                );
                ui.button("Try again")
                    .clicked()
                    .then_some(PickerAction::Retry)
            }
        }
    }

    fn render_choices(ui: &mut Ui) -> Option<PickerAction> {
        if ui.button("Files on this device").clicked() {
            return Some(PickerAction::ChooseLocal);
        }
        if ui.button("Files on another device").clicked() {
            return Some(PickerAction::ChooseRemote);
        }
        None
    }

    fn render_pairing(ui: &mut Ui, view: PickerView<'_>) -> Option<PickerAction> {
        ui.strong("Scan with your phone");
        ui.label("Choose files on the secure page that opens.");
        if let Some(expires) = view.expires_label {
            ui.weak(format!("Expires {expires}"));
        }
        ui.add_space(8.0);

        if let Some(uri) = view.pairing_uri {
            render_qr(ui, uri);
        } else {
            ui.colored_label(ui.visuals().error_fg_color, "QR code unavailable");
        }

        for file in view.files {
            render_file(ui, file);
        }
        ui.button("Cancel")
            .clicked()
            .then_some(PickerAction::Cancel)
    }

    fn render_file(ui: &mut Ui, file: &FileProgress) {
        ui.horizontal(|ui| {
            ui.label(&file.name);
            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                ui.weak(if file.is_complete {
                    "Received".to_owned()
                } else {
                    format!("{}%", file.percent_completed())
                });
            });
        });
        ui.add(egui::ProgressBar::new(file.fraction_completed()).show_percentage());
    }

    fn render_qr(ui: &mut Ui, value: &str) {
        let Ok(code) = QrCode::new(value.as_bytes()) else {
            ui.colored_label(ui.visuals().error_fg_color, "QR code unavailable");
            return;
        };
        let width = code.width();
        let quiet_zone = 4usize;
        let modules = width + quiet_zone * 2;
        let side = 224.0;
        let (rect, _) = ui.allocate_exact_size(Vec2::splat(side), Sense::hover());
        let module = side / modules as f32;
        ui.painter().rect_filled(rect, 0.0, Color32::WHITE);
        let colors = code.to_colors();
        for y in 0..width {
            for x in 0..width {
                if colors[y * width + x] != Color::Dark {
                    continue;
                }
                let min = rect.min
                    + Vec2::new(
                        (x + quiet_zone) as f32 * module,
                        (y + quiet_zone) as f32 * module,
                    );
                ui.painter().rect_filled(
                    egui::Rect::from_min_size(min, Vec2::splat(module.ceil())),
                    0.0,
                    Color32::BLACK,
                );
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn progress_is_bounded_and_zero_size_is_explicit() {
        let progress = FileProgress {
            id: "file".into(),
            name: "photo.jpg".into(),
            bytes_transferred: 12,
            size_bytes: 10,
            is_complete: false,
        };
        assert_eq!(progress.fraction_completed(), 1.0);
        assert_eq!(progress.percent_completed(), 100);

        let empty = FileProgress {
            size_bytes: 0,
            bytes_transferred: 0,
            is_complete: false,
            ..progress
        };
        assert_eq!(empty.fraction_completed(), 0.0);
    }

    #[test]
    fn sensitive_render_states_require_a_pairing_uri() {
        let view = PickerView {
            stage: PickerStage::Pairing,
            ..PickerView::idle()
        };
        assert_eq!(view.validate(), Err(ViewError::MissingPairingUri));

        let valid = PickerView {
            pairing_uri: Some("ftnl://pair#c=redacted-for-test"),
            ..view
        };
        assert_eq!(valid.validate(), Ok(()));
    }

    #[test]
    fn failed_state_requires_a_sanitized_message() {
        let view = PickerView {
            stage: PickerStage::Failed,
            ..PickerView::idle()
        };
        assert_eq!(view.validate(), Err(ViewError::MissingFailureMessage));
    }
}
