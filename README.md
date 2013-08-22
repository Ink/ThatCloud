ThatCloud
=========

ThatCloud is an open-source iOS application built by [Ink](www.inkmobility.com) that helps you Get Work Done. No more saving work until you get back to your desk - with ThatCloud, you can get it done on the go.

ThatCloud integrates with all of your favorites sources of content, from Dropbox and Box to Gmail attachments and Instagram photos. By offering a single place for you to access, view, and work with all of your content, ThatCloud helps simplify your workflow and enhances your iPad productivity. 

Plus, ThatCloud is the first file management system that connects with Ink, offering you a revolutionary new way to take the content you have and work with it in other apps. Take a contract from your email, sign in, and save it to the cloud using ThatCloud. Or grab a photo from Facebook via ThatCloud, crop it and add touchups, and then save it back to Facebook, all in a matter of taps.

A few ThatCloud features:
* See a unified view of the content you care about, including Dropbox, Facebook photos, Gmail attachments, Box, Github, GoogleDrive, Instagram, Flickr, Picasa, SkyDrive.
* Launch that content into other applications using Ink, so that you can view, edit, sign, send, and share your content in your favorite apps in just a few taps.
* Store to your cloud storage from any Ink-enabled app. No more needing to wait until a developer supports your favorite service - just send it to ThatCloud!

With ThatCloud, the iPad is a full-blown productivity device - you no longer need to worry about not having a filesystem on your iPad. The full list of features is detailed in our [blog post](http://blog.inkmobility.com/post/58830177894/introducing-thatcloud-your-portal-to-your-cloud).

ThatCloud is also currently available on the [App Store](https://itunes.apple.com/us/app/thatcloud/id681023311?mt=8)
![ThatCloud in action](https://s3.amazonaws.com/your_own_bucket/Cq4qJEoAQmWLSZXbKedw_awesome)

Ink Integration Details
=======================
The Ink Mobile framework transforms ThatCloud from a simple file preview to a full platform to interact with your content. ThatCloud integrates with Ink in two locations:

  1. ThatCloudAppDelegate registers incoming actions and provides their handlers.
  2. FilePreviewViewController enables the file preview view to transmit content to other Ink enabled apps.

What are the "That" Apps?
=============================

To demonstrate the power Ink mobile framework, Ink created the "ThatApp" suite of sample apps. Along with ThatCloud, there is also ThatInbox for reading your mail, ThatPDF for editing your documents and ThatPhoto for tweaking your photos. But we want the apps to do more than just showcase the Ink Mobile Framework. That's why we're releasing the apps open source. 

As iOS developers we leverage an incredible amount of software created by the community. By releasing these apps, we hope we can make small contribution back. Here's what you can do with these apps:
  1. Use them!
  
  They're your apps and you should be able to do with them what you want. Skin it, fix it, tweak it, improve it. Once you're done, send us a pull request!  

  2. Get your code to the app store 

  All of our sample apps are currently in the App store. Developers learning iOS can get their code in the app store   without having to write an entire app. They only need to send a pull request.

  3. Support other iOS Framework companies
  
  The sample apps are a place where other framework companies can integrate their product to show it off to the world, or simply a place to demonstrate integration strategies to your customers.

  4. Evaluate potential hires
  
  Want to interview an iOS developer? Test their chops by asking them to add a feature or two a real world app.

  5. Show off your skills
  
  Trying to get a job? Point an employer to your merged pull requests to the sample apps as a demonstration of your ability to contribute to real apps.
