"""tools/capture_promo.gd のコマから紹介用GIFを作る。

build/promo/gameplay.gif : 画面全体 960x540(2倍)。ゲーム紹介・SNS用
build/promo/icon.gif     : tools/promo_icon.gd の 144x144 を2倍した 288x288。unityroom のサムネイル(144x144 で表示される)用
実行: python tools/make_promo_gif.py
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
FRAMES = ROOT / "build/promo/frames"
ICON_FRAMES = ROOT / "build/promo/icon_frames"
OUT = ROOT / "build/promo"
FRAME_MSEC = 50
SCALE = 2
PALETTE_COLORS = 255
PALETTE_SAMPLE_STEP = 8


def load_frames(folder: Path) -> list[Image.Image]:
    return [Image.open(p).convert("RGB") for p in sorted(folder.glob("*.png"))]


def shared_palette(frames: list[Image.Image]) -> Image.Image:
    # コマごとに色を選ぶと色がちらつくので、全体から1つの色表を作る
    samples = frames[::PALETTE_SAMPLE_STEP]
    w, h = samples[0].size
    sheet = Image.new("RGB", (w, h * len(samples)))
    for i, frame in enumerate(samples):
        sheet.paste(frame, (0, h * i))
    return sheet.quantize(PALETTE_COLORS, method=Image.Quantize.MEDIANCUT)


def save_gif(frames: list[Image.Image], palette: Image.Image, path: Path) -> None:
    quantized = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    quantized[0].save(
        path, save_all=True, append_images=quantized[1:], duration=FRAME_MSEC, loop=0, optimize=True
    )
    print(f"{path.relative_to(ROOT)}: {quantized[0].size} {len(quantized)}コマ {path.stat().st_size // 1024}KB")


def scaled(frame: Image.Image) -> Image.Image:
    return frame.resize((frame.width * SCALE, frame.height * SCALE), Image.Resampling.NEAREST)


def main() -> None:
    for folder, name in [(FRAMES, "gameplay.gif"), (ICON_FRAMES, "icon.gif")]:
        frames = load_frames(folder)
        if frames:
            save_gif([scaled(f) for f in frames], shared_palette(frames), OUT / name)


if __name__ == "__main__":
    main()
