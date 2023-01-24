list:
	xcodebuild -list

test:
	xcodebuild test -scheme NetManTests -destination "OS=16.2,name=iPhone 14"
