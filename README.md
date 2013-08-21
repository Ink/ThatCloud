ThatCloud
=========

ThatCloud is an open-source iOS application that connects all of your cloud content into the Ink ecosystem of apps. It enables you to take your content from any of 10 different storage locations and view it, interact with it with other Ink partner apps and copy it to other cloud storage locations. The full list of features is detailed in our [blog post](http://blog.inkmobility.com/post/58830177894/introducing-thatcloud-your-portal-to-your-cloud).

Ink is open sourcing  our sample apps for several reasons:
  1. Get your code to the app store 

  All of our sample apps are currently in the App store. Developers learning iOS can get their code in the app store   without having to write an entire App. They only need to send a pull request.


  2. Support other iOS Framework companies
  
  The sample apps are a place where other framework companies can integrate their product to show it off to the world, or simply a place to demonstrate integration strategies to your customers.

  3. Evaluate potential hires
  
  Want to interview an iOS developer? Test their chops by asking them to add a feature or two a real world app.

  4. Show off your skills
  
  Trying to get a job? Point an employer to your merged pull requests to the sample apps as a demonstration of your ability to contribute to real apps.

Ink Integration Details
=======================
The Ink Mobile framework transforms ThatCloud from a simple file preview to a full platform to interact with your content. ThatCloud integrates with Ink in two locations:

  1. ThatCloudAppDelegate registers incoming actions and provides their handlers.
  2. FilePreviewViewController enables the file preview view to transmit content to other Ink enabled apps.
