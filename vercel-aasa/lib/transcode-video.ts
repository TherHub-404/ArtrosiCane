import type { FFmpeg } from '@ffmpeg/ffmpeg';

// Single-threaded ffmpeg core: it needs no SharedArrayBuffer, so the
// dashboard works without cross-origin-isolation (COOP/COEP) headers.
// Loaded from CDN at runtime so the ~30 MB wasm never bloats the bundle.
const CORE_BASE = 'https://unpkg.com/@ffmpeg/core@0.12.6/dist/umd';

let ffmpegPromise: Promise<FFmpeg> | null = null;

async function loadFFmpeg(): Promise<FFmpeg> {
  ffmpegPromise ??= (async () => {
    const { FFmpeg } = await import('@ffmpeg/ffmpeg');
    const { toBlobURL } = await import('@ffmpeg/util');
    const ffmpeg = new FFmpeg();
    await ffmpeg.load({
      coreURL: await toBlobURL(
        `${CORE_BASE}/ffmpeg-core.js`,
        'text/javascript',
      ),
      wasmURL: await toBlobURL(
        `${CORE_BASE}/ffmpeg-core.wasm`,
        'application/wasm',
      ),
    });
    return ffmpeg;
  })();
  return ffmpegPromise;
}

/**
 * Transcodes [file] to a compressed MP4 (H.264 + AAC) suitable for the
 * app's vertical advice reels, entirely in the browser via ffmpeg.wasm.
 *
 * [onProgress] receives a 0..1 ratio. Throws on failure.
 */
export async function transcodeToMp4(
  file: File,
  onProgress: (ratio: number) => void,
): Promise<File> {
  const { fetchFile } = await import('@ffmpeg/util');
  const ffmpeg = await loadFFmpeg();

  const handleProgress = (event: { progress: number }) => {
    if (Number.isFinite(event.progress)) {
      onProgress(Math.min(1, Math.max(0, event.progress)));
    }
  };
  ffmpeg.on('progress', handleProgress);

  const dot = file.name.lastIndexOf('.');
  const inputName = `input${
    dot >= 0 ? file.name.slice(dot).toLowerCase() : '.mov'
  }`;
  const outputName = 'output.mp4';

  try {
    await ffmpeg.writeFile(inputName, await fetchFile(file));
    await ffmpeg.exec([
      '-i', inputName,
      // Cap the width at 720 px (→ 1280 tall for a 9:16 reel), keeping the
      // source aspect ratio. Halves the file size vs 1080-wide.
      '-vf', "scale='min(720,iw)':-2",
      '-c:v', 'libx264',
      '-preset', 'veryfast',
      '-crf', '30',
      '-c:a', 'aac',
      '-b:a', '128k',
      // moov atom up front for progressive playback.
      '-movflags', '+faststart',
      outputName,
    ]);
    const data = await ffmpeg.readFile(outputName);
    const baseName =
      (dot >= 0 ? file.name.slice(0, dot) : file.name).trim() || 'video';
    return new File([data as BlobPart], `${baseName}.mp4`, {
      type: 'video/mp4',
    });
  } finally {
    ffmpeg.off('progress', handleProgress);
    await ffmpeg.deleteFile(inputName).catch(() => {});
    await ffmpeg.deleteFile(outputName).catch(() => {});
  }
}
