=== Setup ===

1. Add your ID to project file. Replace the AppConfiguration.AppBundle.prefix with your ID
2. Select "iPhone 6 Plus" to view SplitViewController master/detail views
——  To run on a device, change AppConfiguration.isSimulator to false
3. Rotate simulator to landscape for master/detail views
4. Three files should display when the app is run

=== Purpose ===

Main objectives:
1. Present files located in iPhone Documents directory to user using GCD DirectoryMonitor
2. Present and edit UIDocument to user as a List protocol
3. Remove all non-essential code to ease understanding. This minimal example is fairly sophisticated and complex.
4. Illustrate an iPhone SplitViewController with master/detail views
5. Extensive GCD async implementations with new Swift 3 DispatchObject classes

=== Limitations ===

1. Add button is disabled because the original Apple code requires Cloud entitlements. Not necessary to illustrate/understand essential concepts.
2. Xcode 8.0 Interface Builder crashed for the CheckBox. I removed the checkbox, so the row color cannot be edited

=== Misc. ===

1. The best way to reach me is by submitting an Issue to the project




















=== ignore ===

https://github.com/kitemike/iosAppleListerExampleSwift3.git

echo "# iosAppleListerExampleSwift3" >> README.md
git init
git add README.md
git commit -m "first commit"
git remote add origin https://github.com/kitemike/iosAppleListerExampleSwift3.git
git push -u origin master

git remote add origin https://github.com/kitemike/iosAppleListerExampleSwift3.git
git push -u origin master
