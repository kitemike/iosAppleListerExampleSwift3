=== Setup ===

1. Add your ID to project file. Replace the AppConfiguration.AppBundle.prefix with your ID
2. Three files should displayed when the app is run
3. To run on a device change AppConfiguration.isSimulator to false
4. Select iPhone 6 Plus to view SplitViewController master/detail views
5. Rotate simulator to landscape for master/detail views

=== Purpose ===

Main objectives:
1. Present files located in iPHone Documents directory to user using DirectoryMonitor
2. Present and edit UIDocument to user as a List
3. Remove all non-essential code to ease understanding. This minimal example is overly complex.
4. Illustrate an iPhone SplitViewController with master/detail views

=== Limitations ===

1. Add button is disabled because the original Apple code requires Cloud entitlements. No necessary to understand essential concepts.
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
