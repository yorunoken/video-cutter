use filetime::{FileTime, set_file_times};
use std::{
    env, fs,
    process::{Command, Stdio, exit},
};

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 3 {
        eprintln!(
            "Usage: {} <video_path> <start_seconds> [end_cut_seconds]",
            args[0]
        );
        exit(1);
    }

    let input_path = &args[1];
    let start_seconds: u64 = args[2].parse().expect("Invalid start time.");

    let end_cut_seconds: u64 = if args.len() >= 4 {
        args[3].parse().expect("Invalid cut end time.")
    } else {
        0
    };

    let output = Command::new("ffprobe")
        .args([
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            input_path,
        ])
        .output()
        .expect("Failed to run ffprove (do you have it installed?)");

    let duration_str = String::from_utf8_lossy(&output.stdout);
    let total_duration: f64 = duration_str
        .trim()
        .parse()
        .expect("Failed to parse duration");

    if (start_seconds as f64) >= total_duration {
        eprintln!("Start time is beyond video duration.");
        exit(1);
    }

    let duration = total_duration - start_seconds as f64 - end_cut_seconds as f64;
    if duration <= 0.0 {
        eprintln!("Invalid duration to cut. Resulting duration is non-positive.");
        exit(1);
    }

    let output_path = format!("cut_{}", input_path);

    let status = Command::new("ffmpeg")
        .args([
            "-ss",
            &start_seconds.to_string(),
            "-i",
            input_path,
            "-t",
            &duration.to_string(),
            "-c",
            "copy",
            &output_path,
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .expect("Failed to run ffmpeg (do you have it installed?)");

    if status.success() {
        let metadata = fs::metadata(input_path).expect("Failed to read input file metadata");

        let modified = FileTime::from_last_access_time(&metadata);
        let accessed = FileTime::from_last_access_time(&metadata);

        set_file_times(&output_path, accessed, modified).expect("Failed to set file timestamps");

        println!("Video cut successfully: {}", output_path);
    } else {
        eprintln!("ffmpeg failed.");
        exit(1);
    }
}
