ThatCloud [![App Store](http://linkmaker.itunes.apple.com/htmlResources/assets/en_us//images/web/linkmaker/badge_appstore-lrg.png)](https://itunes.apple.com/app/id681023311)
=========

ThatCloud is an iOS app that integrates all your cloud storage services so you get work done. No more saving work until you get back to your desk - with ThatCloud, you can get it done on the go.

ThatCloud integrates with all of your favorites sources of content, from Dropbox and Box to Gmail attachments and Instagram photos. By offering a single place for you to access, view, and work with all of your content, ThatCloud helps simplify your workflow and enhances your iPad productivity. 

Plus, ThatCloud is the first file management system that connects with Ink, offering you a revolutionary new way to take the content you have and work with it in other apps. Take a contract from your email, sign in, and save it to the cloud using ThatCloud. Or grab a photo from Facebook via ThatCloud, crop it and add touchups, and then save it back to Facebook, all in a matter of taps.

A few ThatCloud features:
* See a unified view of the content you care about, including Dropbox, Facebook photos, Gmail attachments, Box, Github, GoogleDrive, Instagram, Flickr, Picasa, SkyDrive.
* Launch that content into other applications using Ink, so that you can view, edit, sign, send, and share your content in your favorite apps in just a few taps.
* Store to your cloud storage from any Ink-enabled app. No more needing to wait until a developer supports your favorite service - just send it to ThatCloud!

With ThatCloud, the iPad is a full-blown productivity device - you no longer need to worry about not having a filesystem on your iPad. The full list of features is detailed in our [blog post](http://blog.inkmobility.com/post/58830177894/introducing-thatcloud-your-portal-to-your-cloud).

ThatCloud is also currently available on the [App Store](https://itunes.apple.com/app/id681023311)
![ThatCloud in action](https://s3.amazonaws.com/your_own_bucket/Cq4qJEoAQmWLSZXbKedw_awesome)

License
-------
ThatPDF is an open-source iOS application built by [Ink](www.inkmobility.com), released under the MIT License. You are welcome to fork this app, and pull requests are always encouraged.

How To Contribute
-------------------------
Glad you asked! ThatCloud is based on the [Git flow](http://nvie.com/posts/a-successful-git-branching-model/) development model, so to contribute, please make sure that you follow the git flow branching methodology.

Currently ThatCloud supports iOS6 on iPads. Make sure that your code runs in both the simulator and on an actual device for this environment.

Once you have your feature, improvement, or bugfix, submit a pull request, and we'll take a look and merge it in. We're very encouraging of adding new owners to the repo, so if after a few pull requests you want admin access, let us know.

Every other Thursday, we cut a release branch off of develop, build the app, and submit it to the iOS App Store.

If you're looking for something to work on, take a look in the list of issues for this repository. And in your pull request, be sure to add yourself to the readme and authors file as a contributor.

What are the "That" Apps?
-------------------------

To demonstrate the power of the Ink mobile framework, Ink created the "ThatApp" suite of sample apps. Along with ThatCloud, there is also ThatInbox for reading your mail, ThatPhoto for editing your photos and ThatPDF for signing and annotating documents. But we want the apps to do more than just showcase the Ink Mobile Framework. That's why we're releasing the apps open source. 

As iOS developers, we leverage an incredible amount of software created by the community. By releasing these apps, we hope we can make small contribution back. Here's what you can do with these apps:
  1. Use them!
    
  They are your apps, and you should be able to do with them what you want. Skin it, fix it, tweak it, improve it. Once you're done, send us a pull request. We build and submit to the app store every other week on Thursdays.
  
  2. Get your code to the App Store 

  All of our sample apps are currently in the App Store. If you're just learning iOS, you can get real, production code in the app store without having to write an entire app. Just send us a pull request!

  3. Support other iOS Framework companies
  
  If you are building iOS developer tools, these apps are a place where you can integrate your product and show it off to the world. They can also serve to demonstrate different integration strategies to your customers.

  4. Evaluate potential hires
  
  Want to interview an iOS developer? Test their chops by asking them to add a feature or two to a real-world app.

  5. Show off your skills
  
  Trying to get a job? Point an employer to your merged pull requests to the sample apps as a demonstration of your ability to contribute to real apps.
  
  
Ink Integration Details
-----------------------
The Ink Mobile framework transforms ThatCloud from a simple file preview to a full platform to interact with your content. ThatCloud integrates with Ink in two locations:

  1. [ThatCloudAppDelegate](https://github.com/Ink/ThatCloud/blob/develop/Classes/ThatCloudAppDelegate.m#L29) registers incoming actions and provides their handlers.
  2. [FilePreviewViewController](https://github.com/Ink/ThatCloud/blob/develop/Classes/FilePreviewViewController.m#L121) enables the file preview view to transmit content to other Ink enabled apps.

Contributors
------------
Many thanks to the people who have helped make this app:

* Russell Cohen - [@rcoh](https://github.com/rcoh)
* Liyan David Chang - [@liyanchang](https://github.com/liyanchang)
* Darko Vukovic - [@darkman17](https://github.com/darkman17)
* Brett van Zuiden - [@brettcvz](https://github.com/brettcvz)

Also, the following third-party frameworks are used in this app:

* [Ink iOS Framework](https://github.com/Ink/InkiOSFramework) for connecting to other iOS apps.
* [AFNetworking](https://github.com/AFNetworking/AFNetworking) for communicating with the Ink servers.
* [Apptentive](https://github.com/apptentive/apptentive-ios) for receiving user feedback.
