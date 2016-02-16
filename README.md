![Logo](https://raw.githubusercontent.com/nodes-ios/ModelBoiler/master/Model%20Boiler/Resources/Assets.xcassets/AppIcon.appiconset/Model%20Boiler_128.png)

# Model Boiler

[![Travis](https://img.shields.io/travis/nodes-ios/ModelBoiler.svg)](https://travis-ci.org/nodes-ios/ModelBoiler)
![Plaform](https://img.shields.io/badge/platform-OS X-lightgrey.svg)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/nodes-ios/ModelBoiler/blob/master/LICENSE)


**Model Boiler** is a Mac OS X application used to quickly generate model boilerplate code for models using the `Serializable` protocol.

> TODO: Improve  


## 📦 Installation

### Release
1. Head over to the [latest release](https://github.com/nodes-ios/ModelBoiler/releases/latest).
2. Download the `Model Boiler.app.zip`.
3. Unzip & open the executable file.

### Manual
1. Download or clone the repository.
2. Open the `Model Boiler.xcodeproj`.
3. Archive.
4. Choose Export in the Organizer window.
5. Open the executable located at:  

~~~
~/Desktop/Model Boiler {DATE}/Products/Applications/Model Boiler.app
~~~

## :octocat: Dependencies
#### [Serializable](https://github.com/nodes-ios/Serializable)  
> A protocol to serialize Swift structs and classes for encoding and decoding. 

You will need this dependency if you want to use the generated boiler plate code.
   
####[model-generator](https://github.com/nodes-ios/model-generator)  
The underlying framework used for the actual generation of the code. Can be also used as a command line tool if you choose to go all nerd.

## 👥 Credits
Made with ❤️ at [Nodes](http://nodesagency.com).

## 📄 License
**Model Boiler** is available under the MIT license. See the [LICENSE](https://github.com/nodes-ios/ModelBoiler/blob/master/LICENSE) file for more info.
