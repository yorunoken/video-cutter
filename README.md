# video-cutter

**video-cutter** is a simple Bash script that allows you to cut a portion from any video file using `ffmpeg`.

### Usage

```bash
video-cutter ./video.mp4 [start_second] [end_second]
```

* `start_second` – The timestamp (in seconds) where the cut should begin.
* `end_second` *(optional)* – The timestamp (in seconds) where the cut should end.
  If omitted, the video will be cut from `start_second` to the end of the file.
