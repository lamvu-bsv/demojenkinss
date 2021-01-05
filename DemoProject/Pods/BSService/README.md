# BSService
Calling network api to remote server is one of the most common tasks every app performs. Nowadays there are many framework support this. But because of typical aspects of outsourcing, there are practical needs emerged these frameworks cannot satisfy:  

1. Provide a flexible mapping mechanism from json response to object. Such as: many api provide the same object but with different structure and field names.
2. Provide a way to set up `URLRequest` quickly and easily.
3. Support developer for customizing way to distinguish between success and fail api call. Because each api provide has a different data organizing between those 2 cases.
4. Provide developer a way to specify common response handling for every api. Such as: access token expired, forced update, ... 
5. Support config load animation quickly and easily.
6. Support set up handling for many different api provider but still the same above attributes.  

From those requirements, [BSService](https://bsvframeworks@bitbucket.org/bravesoftvietnam/bsservice.git) was created to help developer to not only handle api networking quickly and easily, but also satisfy requirements for maintenance and future extension. Thus helps developer spend more time on improve app's quality.

## Install cocoapod spec repo
Before running example or install, please run command:  
```ruby
pod repo
```
In order to check whether the cocoapod spec with the following url has been installed or not:  
```ruby
https://bsvframeworks@bitbucket.org/bravesoftvietnam/cocoapods-specs.git
```
If not, run the following command:  
```ruby
pod repo add bsv_frameworks https://bsvframeworks@bitbucket.org/bravesoftvietnam/cocoapods-specs.git
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

BSService is available through [CocoaPods](https://cocoapods.org). To install it, first the beginning add the following border to your Podfile:  
```ruby
source 'https://github.com/CocoaPods/Specs.git'
source 'https://bsvframeworks@bitbucket.org/bravesoftvietnam/cocoapods-specs.git'
```  
then add:  
```ruby
pod 'BSService'
```
After that make sure this line is not commented:  
```ruby
use_frameworks!
```
If encounter error `[!] Unable to find a specification ...` upon running `pod install` then perform step **Install cocoapod spec repo** above.  
After that rerun command `pod install`

## Usage

### Service's components
A service has 4 following components:  

1. Service: Handle connecting network, routing response and handle other components.
2. Configuration: Object which from subclass of URLRequestConfiguration. Use for config url request quickly and conveniently. Moreover they store information about request supporting for debug more easily.  
3. Info: Model object stores json info received from server. If api request is success, service will parse json into object automatically and then include in result callback.  
4. Parser: Handle parsing from response data (json, xml, ...) to object. Because each api provider has its own response data structure, parser is created separately in order to help handling response data dynamically and conveniently. Depend on developer's purpose services can share one parser, or each parse use a different parser.  

### Subclass mechanism of BSService
The following image demonstrate example how to subclass BSService for using in your project:  
![alt text](Images/class_structure.jpg "Class structure")  

- `BSService`: This is the origin service class which implements handling base flow network. Do not use this class directly.
- `CommonService`: Handle api of the main api provider for your project. All service of project should be subclass of `CommonService`.
- `SampleService`: Handle for sample api, in case of demo or testing framework.  
- `CustomService`: Handle share feature of `CommonService` and `SampleService`.  
 
### Flow callbacks
![alt text](Images/execution.jpg "Execution")  

### Essentials properties + methods when using BSService
#### Main properties:  
1. `parser`: Parser is the object which in charge of parsing raw data received from server into object.
2. `completionQueue`: The queue on which the service's callback will be called.
3. `configuration`: Configuration for generating URLRequest object.

#### Properties for handling callback:  
1. `success`: Closure handling for success case.
2. `error`: Closure handling for error case, which could be network error or error return by server.
3. `finish`: Handler before finishing a service. This will be called after either success and error.

#### Properties for convenient UI handling:  
1. `progressHudContainer`: The container of progress hud, if nil then not show. Default is nil.
2. `activityIndicatorContainer`: Auto add an activity indicator to specify container and remove when finish service.
3. `scrollView`: Auto turn of refresh control, and also set isHidden to false when finish service.
4. `activityIndicator`: Activity indicator which appear in activityIndicatorContainer.

#### Methods for deeper callbacks customizing between many service:
1. `open func callEventConnectionSuccess(withData: Any?)`: Override to custom call update state events for success case, if not don't override.
2. `open func callEventConnectionError(error: Error)`: Override to custom call update state events for error case, if not don't override.
3. `open func callEventConnectionWillFinish()`: Network finish callback to redirect to suitable callback.

#### Methods for customizing between different api provider.
1. `open func execute()`: Executing request of the service. You can also override this function to add more behavior. Such as: add an access token for every services.
2. `open func connectionDidFinish(with response: URLResponse?, data: Data?)`: Network finish callback to redirect to suitable callback.

### Use BSService in your project  
**Step 1.** Create object Info map from response data (json, xml, ...) to object from api, for example:  
```swift
class ArticleInfo: NSObject {
    var id: String?
    var blogId: String?
    ...
} 
```  

**Step 2.** Create url, you can place on anywhere in your code. In this example, the url is placed in enum `APIUrlDef`
```swift
public enum APIUrlDef {
    static let APIPath = "v1"

    case checkversion
    ....
    case getarticles // Insert tên url trong enum

    ...    

    public func urlString() -> String {
        switch self {
            case .getarticles: // Thêm case khi convert enum sang String
            return ConstantAPI.apiPath() + "/:id/campaign_and_others_info_get"
        }
    }
}
```  

**Step 3.** Create parser in order to parse response data into object, override method `parseJson`, example:
```swift
class GetArticleListParser: BSServiceParser {
    override func parseJson(object: Any?) -> Any? {
        let jsonArray = object as! Array<Dictionary<AnyHashable, AnyHashable>>
        var articles = Array<ArticleInfo>()
        for json in jsonArray {
            let article = ArticleInfo()
            article.id = json["id"] as? String
            article.blogId = json["blog_id"] as? String
            ...
            articles.append(article);
        }
        return articles;
    }
}
```  

**Step 4.** Create service and config for request api, example:
```swift
class GetArticleListService: CommonService {
    public func getArticleListWithUUID (uuid: String, petId: String,listForType: String) {
        self.parser = GetArticleListParser()
        var params = Dictionary<String, Any>()
        params["uuid"] = uuid
        params["id"] = petId
        params["listForType"] = listForType
        let configuration = URLRequestNormalConfiguration()
        configuration.method = .get
        configuration.url = APIUrlDef.getarticles.urlString();
        configuration.bodyParams = params;
        self.configuration = configuration;
    }
}
```  
**Note**: If there is no need for parsing data, set service's parser as an instance of `BSServiceParser`.
If the case is post file, set up configuration as following:
```swift
let configuration = URLRequestPostFileConfiguration()
var file : URLRequestFileConfiguration = URLRequestFileConfiguration()
file.file = UIImageJPEGRepresentation(UIImage(named: "image")!, 1.0)
file.key = "image"
file.name = "image_name.jpg"
file.mimeType = "image/jpeg"
configuration.files = Array(file)
configuration.url = APIUrlDef.getarticles.urlString();
configuration.bodyParams = params;
```  
If the url has components like `/[variable_name]` as example in step 2 (`/:id/campaign_and_others_info_get`), the url should be defined like `/:variable_name`. This is a convention applied by many frameworks. When config we will set into `configuration.urlParams` like the following:
```swift
var urlParams = Dictionary<String, Any>()
urlParams[":id"] = 123
configuration.urlParams = urlParams;
```
The url in the example should be: `/123/campaign_and_others_info_get`  

**Step 5.** Call service execution:  
```swift
let campaignService = GetArticleListService()        
campaignService.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray;
campaignService.success = { (data: Any?) in
    if let articles = data as? Array<ArticleInfo> {
        if loadMore == false {
            self.articles.removeAll()
        }
        self.articles.append(contentsOf: articles)
        self.listTableView.showsInfiniteScrolling = (self.articles.count < 50)
    }
}
campaignService.finish = {
    self.listTableView.reloadData()
}
campaignService.getArticleListWithUUID(uuid: "6BB7A8B5-5193-41ED-8162-9185A168D4A4", petId: "992126", listForType: "")
campaignService.execute() 
```  

### Reuse parser with `ObjectParser` and `ConvenienceServiceParser`. 
`BSService` provide a way for reuse parse object code. Including 2 classes: `ConvenientServiceParser` and `ObjectParser`.
### How to used
**Step 1.** Create a subclass of `ObjectParser` and implement `objectFromJson` method:
```swift
class OptionParser: ObjectParser {
    override func objectFromJson(_ json: Dictionary<AnyHashable, Any>) -> Any? {
        let object = OptionInfo()
        object.id = json["id"] as? String
        object.en = json["en"] as? String
        object.jp = json["jp"] as? String
        return object
    }
}
```

**Step 2.** When implement service, set `parser` property to `ConvenientServiceParser`. This class needs 2 params including:
`objectParser`: Init from step 1.
`dataNeedToParse`: The closure which is use to take data need to parse as input into object parser.
For example, response data is:
```json
{
"data": [
    {
        "id": 1,
        "en": "Text",
        "jp": "Text"
    },
    {
        "id": 2,
        "en": "Text 2",
        "jp": "Text 2"
    }
]
}
```  
then in service's parser property will be set as follow:
```swift
class GetOptionItemsService: CommonService {
    func getOptionItems(type: OptionItem) {
        self.autoFillAccessToken = false
        self.parser = ConvenientServiceParser(objectParser: OptionParser(), dataNeedToParse: { (responseData : Any?) -> Any? in
            guard let dict = responseData as? Dictionary<Any, Any> else { return responseData }
            return dict["data"]
        })
        var bodyParams : Dictionary<String, String> = [:]
        let configuration = URLRequestNormalConfiguration()
        configuration.method = .get
        configuration.url = ConstantAPI.optionItems.urlString()
        configuration.bodyParams = bodyParams
        self.configuration = configuration
    }
}
```  
Another case api return value as below:
```json
{
"abc_xyz": [
    {
        "id": 1,
        "en": "Text",
        "jp": "Text"
    },
    {
        "id": 2,
        "en": "Text 2",
        "jp": "Text 2"
    }
]
}
```  
then set parser will be:
```swift
self.parser = ConvenientServiceParser(objectParser: OptionParser(), dataNeedToParse: { (responseData : Any?) -> Any? in
    guard let dict = responseData as? Dictionary<Any, Any> else { return responseData }
    return dict["abc_xyz"]
})
```  
By using this way code parse object can be reused easily and dynamically.

### Combine multiple services using NSOperation
In order to combine multiple services easily and quickly. `BSService` has integrated with `NSOperation` in order to use with `NSOperationQueue`. To create a NSOperation from a service, class `BSServiceOperation` is provided as follow:
```swift
let operation: Operation = BSServiceOperation(service: sv)
```
The following is code sample provide more detail about how to use `BSServiceOperation`:
```swift
let queue: OperationQueue = OperationQueue()
let campaignService: GetArticleListService = GetArticleListService()
campaignService.getArticleListWithUUID(uuid: "6BB7A8B5-5193-41ED-8162-9185A168D4A4", petId: "992126", listForType: "")
campaignService.ignoreCancelError = false
campaignService.success = {(data: Any?) in
    result.getArticleResult = data
}
campaignService.logicError = logicError
campaignService.networkError = networkError
let operation: Operation = BSServiceOperation(service: campaignService)
completion.addDependency(operation)
queue.addOperation(operation)
```
In source Example of this repo, you can view class `CompositeService` for more detail.

## Author

Hien, hienpham@bravesoft.com.vn

## License

BSService is available under the APACHE license. See the LICENSE file for more info.
