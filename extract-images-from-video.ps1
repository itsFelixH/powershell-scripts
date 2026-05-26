
$VideoFiles=(Get-ChildItem * -recurse | Where-Object {$_.extension -in ".mp4"});
$numFiles=($VideoFiles | Measure-Object).Count;

Write-Host "Converting $numFiles file(s)..."

# converting/compressing files
$VideoFiles | ForEach-Object {

	Write-Host "`n"
	Write-Host "Processing '$_'"

	$numFrames=8

	$inputFile="$_"
	$outputFile="output\" + $_.BaseName + "-%03d.jpg"
	$outputFileKeys="output\" + $_.BaseName + "-key%02d.jpg"
	$outputFileLast="output\" + $_.BaseName + "-last.jpg"

	$framesString=(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -i $inputFile)[1]
	$position=$framesString.IndexOf("=")
	$totalFrames=$framesString.Substring($position+1)

	Write-Host "Video has $totalFrames frames. Extracting $numFrames images"
	$rate=[math]::Floor($totalFrames/$numFrames)

	# ffmpeg -v quiet -stats -y -hide_banner -i $inputFile -vframes 1 -update true $outputFile

	# extracting all frames
	# ffmpeg -i big_buck_bunny_720p_2mb.mp4 -r 1 frame%d.png

	# extracting a single frame
	# ffmpeg -i big_buck_bunny_720p_2mb.mp4 -ss 00:00:05 -vframes 1 frame_out.jpg

	# extracting n frames
	# ffmpeg -i big_buck_bunny_720p_2mb.mp4 -r 10 -vframes 25 frame%04d.jpg

	# image every 25 frames
	# ffmpeg -i <your-input> -ss 0.0 -vframes 1 -y first.png -vf fps=25/51 -y 51th_%02d.png -ss 60.0 -vframes 1 -y last.png

	# extract n frames (including first)
	ffmpeg -v quiet -y -hide_banner -i $inputFile -f image2 -vf "select='not(mod(n,$rate))'" -vframes $numframes -vsync vfr $outputFile
	# extract last frame
	ffmpeg -v quiet -y -hide_banner -i $inputFile -f image2 -vf "select='eq(n,$($totalFrames-1))'" -vframes 1 $outputFileLast

	# get every 10th frame
	# ffmpeg -i $inputFile -ss 0.0 -vframes 1 -y $outputFileFirst -vf fps=25/51 -y $outputFile
	# ffmpeg -i $inputFile -vf "select='not(mod(n,10))'" -vsync vfr $outputFile

	# get keyframes
	ffmpeg -v quiet -y -hide_banner -i $inputFile -vf "select=eq(pict_type\,I)" -vsync vfr $outputFileKeys
}