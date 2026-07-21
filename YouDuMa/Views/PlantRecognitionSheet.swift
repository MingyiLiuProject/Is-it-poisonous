import PhotosUI
import SwiftUI
import UIKit

struct PlantRecognitionSheet: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isCameraPresented = false
    @State private var phase: RecognitionPhase = .idle
    @State private var recognitionTask: Task<Void, Never>?

    let onSelect: (Plant) -> Void
    let onUseSearch: (String) -> Void

    private let recognizer = VisionPlantRecognizer()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    introduction

                    if let selectedImage {
                        imagePreview(selectedImage)
                    }

                    phaseContent
                    sourceControls
                }
                .padding(18)
                .padding(.bottom, 12)
            }
            .background(AppTheme.cream.ignoresSafeArea())
            .navigationTitle("识别植物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $isCameraPresented) {
            CameraPicker { image in
                startRecognition(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            loadPhoto(newItem)
        }
        .onDisappear {
            recognitionTask?.cancel()
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("设备端初步识别", systemImage: "camera.macro")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.forest)
            Text("尽量让一株植物占据画面，并拍清叶片或花。照片不会上传；识别结果需要由你确认。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appCard()
    }

    private func imagePreview(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                Label("仅在设备端处理", systemImage: "lock.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(12)
            }
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch phase {
        case .idle:
            ContentUnavailableView(
                "选择一张植物照片",
                systemImage: "photo.on.rectangle.angled",
                description: Text("模型会返回最多三个可能的植物")
            )
            .frame(minHeight: 180)

        case .analyzing:
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                Text("正在分析叶片、花和整体特征…")
                    .font(.subheadline.weight(.medium))
                Text("识别在设备端完成")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 180)
            .appCard()

        case .results(let result):
            if result.candidates.isEmpty {
                noMatch(result)
            } else {
                candidateList(result)
            }

        case .failure(let message):
            ContentUnavailableView(
                "识别没有完成",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .frame(minHeight: 180)
        }
    }

    private func candidateList(_ result: PlantRecognitionResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("可能是")
                    .font(.headline)
                Spacer()
                Text("请选择最接近的一项")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(result.candidates) { candidate in
                Button {
                    onSelect(candidate.plant)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        PlantRemoteImage(
                            url: candidate.plant.image?.thumbnail,
                            accessibilityLabel: "\(candidate.plant.chineseName)植物照片"
                        )
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(candidate.plant.chineseName)
                                .font(.headline)
                            Text(candidate.plant.englishName)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.forest)
                            Text(candidate.plant.acceptedScientificName)
                                .font(.caption.italic())
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 4)

                        VStack(alignment: .trailing, spacing: 5) {
                            Text(candidate.confidence, format: .percent.precision(.fractionLength(0)))
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(AppTheme.forest)
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(14)
                    .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .appCard(cornerRadius: 20)
                }
                .buttonStyle(PressableCardButtonStyle())
                .accessibilityHint("打开该植物的毒性详情")
            }

            Text("置信度仅表示图片分类相似度，不代表植物学鉴定结论。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func noMatch(_ result: PlantRecognitionResult) -> some View {
        VStack(spacing: 14) {
            ContentUnavailableView(
                "无法可靠匹配",
                systemImage: "questionmark.app",
                description: Text("请换一个角度，拍清叶片或花；也可以使用识别关键词继续搜索。")
            )

            if let label = result.observedLabels.first {
                Button {
                    onUseSearch(label)
                    dismiss()
                } label: {
                    Label("搜索“\(label)”", systemImage: "magnifyingglass")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(.white)
                        .background(AppTheme.forestFill, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(PressableControlButtonStyle())
            }
        }
        .padding(16)
        .appCard()
    }

    private var sourceControls: some View {
        HStack(spacing: 12) {
            Button {
                isCameraPresented = true
            } label: {
                Label("拍照", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.forestFill)
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("相册", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.forest)
        }
    }

    @MainActor
    private func loadPhoto(_ item: PhotosPickerItem) {
        recognitionTask?.cancel()
        phase = .analyzing
        recognitionTask = Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw PlantRecognitionError.invalidImage
                }
                guard !Task.isCancelled else { return }
                startRecognition(image)
            } catch is CancellationError {
                return
            } catch {
                withAnimation(AppMotion.responsive(reduceMotion: reduceMotion)) {
                    phase = .failure(error.localizedDescription)
                }
            }
        }
    }

    @MainActor
    private func startRecognition(_ image: UIImage) {
        recognitionTask?.cancel()
        selectedImage = image
        phase = .analyzing

        recognitionTask = Task {
            do {
                let result = try await recognizer.recognize(image)
                guard !Task.isCancelled else { return }
                withAnimation(AppMotion.responsive(reduceMotion: reduceMotion)) {
                    phase = .results(result)
                }
            } catch is CancellationError {
                return
            } catch {
                withAnimation(AppMotion.responsive(reduceMotion: reduceMotion)) {
                    phase = .failure(error.localizedDescription)
                }
            }
        }
    }
}

private enum RecognitionPhase {
    case idle
    case analyzing
    case results(PlantRecognitionResult)
    case failure(String)
}
