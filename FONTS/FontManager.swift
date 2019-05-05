//  FontManager.swift
//  CreatedApp
//  Created by RohitChauhan on 25/03/19.

import Foundation
import CoreText

public protocol FontManagerAPI {
    //This function is used to get Font.
    func font(name:String, size:CGFloat, callback:@escaping (_ font:UIFont)->Void) throws
    
    //This function is used to get Font With FontDescription
    func font(name:String, fontDescription:FontSizeDescriptor,  uiType:UIType, callback:@escaping (_ font:UIFont)->Void) throws
    
    //After initialize the font manager, use this function to download fonts
    //family form remote
    func downloadAllFont()
    
}


@objc open class FontManager:NSObject {
    private var fontBaseUrl:String?
    private var fontCurrentValue = 0;
    private var fontList:[String]?
    private var registeredFontData:[String:String] = [:]
    private var fontsRemoteUrls:[String]?
    private var isuseRemoreUrls:Bool
    
    private override init(){
        self.isuseRemoreUrls = false
        super.init()
        
    }
    
    @objc public static var shared = {
        return FontManager()
        
    }()
    
    @objc open func setFontBaseurl(urlString:String) {self.fontBaseUrl = urlString }
    fileprivate func getFontBaseurl()-> String? { return self.fontBaseUrl }
    
    @objc open func setFonts(list fontnames:[String]) { self.fontList = fontnames }
    fileprivate func getFontsName()->[String]? {return self.fontList }
    
    @objc open func setfontsRemoteUrls(fontRemoteUrls urls:[String]) {self.fontsRemoteUrls = urls }
    fileprivate func getfontsRemoteUrls()->[String]? {return self.fontsRemoteUrls }
    
    @objc open func  setisuseRemoteUrls(status:Bool) {self.isuseRemoreUrls = status }
    fileprivate func  getisuseRemoteUrls()->Bool {return self.isuseRemoreUrls }
    
    //Use this function to get font name and extension and extension from fontname.extension
    private func getFontNameAndExtension(fontname:String)->(fontFamilyName:String, fontExtension:String)? {
        let arr = fontname.components(separatedBy: ".")
        if(arr.count == 2) {return (arr[0], arr[1]);  }
        if(arr.count == 1) {return (arr[0], "");}
        
        return nil
    }
    
    //Use this function to get font name and extension from font url
    private func getFonfamilyname_andExtension(for url:String)->(fontFamilyName:String, fontExtension:String)? {
        let arr  = url.components(separatedBy: "/")
        if let  fontNamewithExt = arr.last {
            return getFontNameAndExtension(fontname:fontNamewithExt)
            
        }
        
        return nil
    }
    
    //Use this function to get font extension and extension from fontname.extension
    private func getFontExtensionfor(fontName:String)throws ->(fontFamilyName:String, fontExtension:String) {
        if self.fontList?.count == 0 {throw  FontError.FontnotAvailable }
        
        let fontNameWithExtension = self.fontList?.filter{ $0.lowercased().contains(fontName.lowercased()) }.first
        
        if let tmp = fontNameWithExtension, let fontTuple = self.getFontNameAndExtension(fontname: tmp), fontTuple.fontExtension.count != 0 {
            return fontTuple
            
        }
        
        throw FontError.FontnotAvailable
    }
    
    
    open func font(name:String, size:CGFloat, callback:@escaping (_ font:UIFont)->Void) throws {
        if let fonttuple = self.getFontNameAndExtension(fontname: name) {
            do {
                try self.getFontWith(name: fonttuple.fontFamilyName, fontExtension:fonttuple.fontExtension , size: size, callback: callback)
                
            }catch {
                callback(UIFont.systemFont(ofSize: size))
                debugPrint(error.localizedDescription)
                
            }
            
        }
        
    }
    
    open func font(name:String, fontDescription:FontSizeDescriptor,  uiType:UIType, callback:@escaping (_ font:UIFont)->Void)throws {
        if let fonttuple = self.getFontNameAndExtension(fontname: name) {
            do {
                try self.getFontWith(name: fonttuple.fontFamilyName, fontExtension:fonttuple.fontExtension , size: CGFloat(uiType.uiFontSize(fontdescriptor: fontDescription)), callback: callback)
                
            }catch {
                callback(UIFont.systemFont(ofSize: CGFloat(uiType.uiFontSize(fontdescriptor: fontDescription))))
                debugPrint(error.localizedDescription)
                
            }
            
        }
        
    }
    
}

//MARK:- MANAGE DOCUMENT DIRECTORY FOR FONT
extension FontManager {
    //Use this function to create font directory and save font data to this directory
    private func saveFont(data:Data, fontFamilyName:String,callback:((_ status:Bool)->Void)? = nil) {
        let documentDirectoryPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let fontDirectoryPath = documentDirectoryPath.appendingPathComponent("Fonts")
        
        if !FileManager.default.fileExists(atPath: fontDirectoryPath!.path) {
            do
            {
                try FileManager.default.createDirectory(atPath: fontDirectoryPath!.path, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError
            {
                NSLog("Unable to create directory \(error.debugDescription)")
            }
            
        }
        
        let fontPath = fontDirectoryPath?.appendingPathComponent(fontFamilyName)
        
        if !FileManager.default.fileExists(atPath: fontPath!.path) {
            do {
                try data.write(to: fontPath!, options: .atomic)
                if callback != nil {callback!(true) }
                
            }catch {
                if callback != nil {callback!(false) }
                debugPrint(error.localizedDescription)
                
            }
            
            if  let url = fontPath, let fontname = self.registerfont(with : url) {
                let tmpfont = url.lastPathComponent
                let tmpArr = tmpfont.components(separatedBy: ".")
                
                if tmpArr.count > 0 {
                    let fontLocalName = tmpArr[0]
                    if self.registeredFontData[fontLocalName] == nil {
                        self.registeredFontData[fontLocalName] = fontname as String
                        
                    }
                    
                }
                
            }
            
        }else {
            if callback != nil {callback!(true) }
            
        }
        
    }
    
    private func getFontWith(name:String, fontExtension:String, size:CGFloat, callback:@escaping (_ font:UIFont)->Void) throws {
        if fontAvailableForCurrentDevice(fontFamilyName: name).isAvail {
            if let finalFont = UIFont(name: fontAvailableForCurrentDevice(fontFamilyName: name).fontFamilyName, size: size) {
                callback(finalFont)
                
                return
            }
            
            callback(UIFont.systemFont(ofSize: size))
            
            return
        }
        
        if fontExistInDocumentDirectory(fontFamilyName: name, fontExtension: fontExtension) {
            do {
                try getFontfromDirectory(name: name, size: size, callback:callback);
                
            }catch {
                callback(UIFont.systemFont(ofSize: size))
                
            }
            
        }
        
        if name.count > 0 {
            do {
                try getFont_fromRemote(fontName: name, fontExtension: fontExtension, size: size, callback: callback)
                
            }catch {
                callback(UIFont.systemFont(ofSize: size))
            }
            
        }
        
    }
    
    private func getFontfromDirectory(name:String, size:CGFloat, callback:(_ font:UIFont)->Void) throws {
        var fontPath:NSString = (NSHomeDirectory() as NSString).appendingPathComponent("Documents") as NSString
        fontPath = fontPath.appendingPathComponent(String(format: "%@/%@","Fonts", name)) as NSString
        let fontFileUrl = URL(fileURLWithPath: fontPath as String)
        
        var fontError: Unmanaged<CFError>?
        
        if let fontDataProvide = CGDataProvider(url: fontFileUrl as CFURL), let newFontRef = CGFont(fontDataProvide) {
            if let postScriptName = newFontRef.postScriptName {
                
                if CTFontManagerRegisterGraphicsFont(newFontRef, &fontError) {
                    
                    if  let finalFont = UIFont(name: postScriptName as String, size: size) {
                        callback(finalFont)
                        
                    }
                    
                }else {
                    debugPrint("Font Already Registered Error \(fontError.self.debugDescription) ")
                    if  let finalFont = UIFont(name: postScriptName as String, size: size) {
                        callback(finalFont)
                        
                    }
                    
                }
                
                self.registeredFontData[name] = postScriptName as String
            }
            
        }else  {
            debugPrint("Font Creation Error \(fontError.self.debugDescription) ")
            
            callback(UIFont.systemFont(ofSize: size))
            
        }
        
    }
    
}

//MARK:- REMOTE CALLS FOR FONT
extension FontManager {
    @objc  open func downloadAllFont() {
        self.fontCurrentValue = 0
        
        if self.isuseRemoreUrls {
            downloadFonst_fromFontUrls();
            return;
        }
        
        downloads_fromFontList()
        
    }
    
    private func downloadFonst_fromFontUrls() {
        if let fontRemoteUrls = self.fontsRemoteUrls {
            if fontRemoteUrls.count > self.fontCurrentValue, let url = fontRemoteUrls [self.fontCurrentValue] as? String, let fonttuple = self.getFonfamilyname_andExtension(for: url){
                
                if checkFontAlreadyExist(fontFamilyName: fonttuple.fontFamilyName, fontExtension: fonttuple.fontExtension) {
                    self.fontCurrentValue += 1;
                    downloadFonst_fromFontUrls()
                }else {
                    request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil).response { (response) in
                        
                        if let data = response.data {
                            self.saveFont(data: data, fontFamilyName: fonttuple.fontFamilyName, callback:nil)
                            
                        }
                        
                        self.fontCurrentValue += 1;
                        self.downloadFonst_fromFontUrls()
                    }
                    
                }
                
            }else  {
                self.fontCurrentValue += 1;
                if(self.fontCurrentValue >= self.fontCurrentValue) {return; }
                self.downloadFonst_fromFontUrls()
                
            }
            
        }
        
    }
    
    private func downloads_fromFontList() {
        if let fontNames = self.fontList {
            if fontNames.count > self.fontCurrentValue, let fonttuple = self.getFontNameAndExtension(fontname: fontNames[self.fontCurrentValue]), let url = self.getFontUrl(fontTuple: fonttuple) {
                
                if checkFontAlreadyExist(fontFamilyName: fonttuple.fontFamilyName, fontExtension: fonttuple.fontExtension) {
                    self.fontCurrentValue += 1;
                    downloads_fromFontList()
                }else {
                    request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil).response { (response) in
                        
                        if let data = response.data {
                            self.saveFont(data: data, fontFamilyName: fonttuple.fontFamilyName, callback:nil)
                            
                        }
                        
                        self.fontCurrentValue += 1;
                        self.downloads_fromFontList()
                    }
                    
                }
                
            }else  {
                self.fontCurrentValue += 1;
                if(self.fontCurrentValue >= self.fontCurrentValue) {return; }
                self.downloads_fromFontList()
                
            }
            
        }
        
    }
    
    private func getFontUrl(fontTuple:(String,String))->URL? {
        if let baseurl = self.fontBaseUrl {
            return URL(string:  String(format: "%@%@.%@", baseurl,fontTuple.0, fontTuple.1))
            
        }
        
        return nil
    }
    
    private func getFont_fromRemote(fontName:String, fontExtension:String?, size:CGFloat,callback:@escaping (_ font:UIFont)->Void) throws {
        var fontTuple:(String, String) = (fontName, fontExtension ?? "")
        
        if !(fontExtension != nil) || fontTuple.1.count == 0 {
            do {
                fontTuple = try self.getFontExtensionfor(fontName: fontName)
                
            }catch {
                callback(UIFont.systemFont(ofSize: 20.0))
                
            }
            
        }
        
        if let url = self.getFontUrl(fontTuple: fontTuple) {
            request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: nil).response { (response) in
                
                if let data = response.data {
                    self.saveFont(data: data, fontFamilyName: fontTuple.0,callback: {(status) in
                        if status {
                            do {
                                if let fontScriptName = self.registeredFontData[fontTuple.0], !fontScriptName.isEmpty {
                                    callback(UIFont(name: fontScriptName, size: size) ?? UIFont.systemFont(ofSize: size))
                                }else {
                                    try self.getFontfromDirectory(name: fontTuple.0, size: size, callback: callback)
                                    
                                }
                                
                            }catch {
                                callback(UIFont.systemFont(ofSize: size))
                                
                            }
                            
                        }else  {
                            
                            do {
                                try self.getFontfromDirectory(name: fontTuple.0, size: size, callback: callback)
                                
                            }catch {
                                callback(UIFont.systemFont(ofSize: 16.0))
                                
                            }
                            
                        }
                        
                    })
                    
                }
                
            }
        }
        
    }
    
}

//MARK: Font Register
extension FontManager {
    @objc open func registerAllFont() {
        
        let documentDirectoryPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        
        
        if let fontDirectoryPath = documentDirectoryPath.appendingPathComponent("Fonts"), FileManager.default.fileExists(atPath: fontDirectoryPath.path) {
            
            do {
                let directoryContent = try FileManager.default.contentsOfDirectory(atPath: fontDirectoryPath.path)
                
                for i in 0 ..< directoryContent.count {
                    if  let fontname = self.registerfont(with : fontDirectoryPath.appendingPathComponent(directoryContent[i])) {
                        let tmpfont = (directoryContent[i] as NSString).lastPathComponent
                        let tmpArr = tmpfont.components(separatedBy: ".")
                        
                        if tmpArr.count > 0 {
                            let fontLocalName = tmpArr[0]
                            if self.registeredFontData[fontLocalName] == nil {
                                self.registeredFontData[fontLocalName] = fontname as String
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }catch {
                debugPrint("content of directory open issue \(error.localizedDescription)")
                
            }
            
        }
        
    }
    
    private func registerfont(with fontFileUrl:URL, size:CGFloat = 16, callback:((_ font:UIFont)->Void)? = nil)->NSString? {
        if let fontTuple = self.getFonfamilyname_andExtension(for: fontFileUrl.absoluteString), let  registeredFont = self.isFontalredyRegistered(fontlocalName:fontTuple.fontFamilyName) {
            callback?(UIFont(name: registeredFont.registeredFamilyname, size: size) ?? UIFont.systemFont(ofSize: size))
            
            return nil
        }
        
        var fontError: Unmanaged<CFError>?
        
        if let fontDataProvide = CGDataProvider(url: fontFileUrl as CFURL), let newFontRef = CGFont(fontDataProvide) {
            
            if let fontName = newFontRef.postScriptName {
                if CTFontManagerRegisterGraphicsFont(newFontRef, &fontError) {
                    if  let finalFont = UIFont(name: fontName as String, size: size) {
                        callback?(finalFont)
                        return fontName as NSString;
                    }
                    
                }else {
                    debugPrint("Font Creation Error \(fontError.self.debugDescription) ")
                    if let finalFont = UIFont(name: fontName as String, size: size) {
                        callback?(finalFont)
                        
                    }
                    
                }
                
                return fontName as NSString
            }
            
        }else  {
            debugPrint("Font Creation Error \(fontError.self.debugDescription) ")
            callback?(UIFont.systemFont(ofSize: size))
            
        }
        
        return nil
    }
    
}


//MARK:- FONT EXISTENCE CHECKER
extension FontManager {
    private func checkFontAlreadyExist(fontFamilyName:String, fontExtension:String)->Bool {
        if fontExistInDocumentDirectory(fontFamilyName: fontFamilyName, fontExtension: fontExtension) {return true; }
        if fontAvailableForCurrentDevice(fontFamilyName: fontFamilyName).isAvail {return true; }
        
        return false;
    }
    
    private func fontExistInDocumentDirectory(fontFamilyName:String, fontExtension:String)->Bool {
        var fontPath:NSString = (NSHomeDirectory() as NSString).appendingPathComponent("Documents") as NSString
        fontPath = fontPath.appendingPathComponent(String(format: "%@/%@","Fonts", fontFamilyName)) as NSString
        
        if FileManager.default.fileExists(atPath: fontPath as String) {return true; }
        
        return false;
    }
    
    private func fontAvailableForCurrentDevice(fontFamilyName:String)->(isAvail:Bool, fontFamilyName:String) {
        if let registeredFont = self.isFontalredyRegistered(fontlocalName: fontFamilyName) {
            return (registeredFont.fontStatus, registeredFont.registeredFamilyname)
            
        }
        
        for familyNam in UIFont.familyNames {
            debugPrint("Available Font Family \(familyNam)")
            let tmp = familyNam.components(separatedBy: " ")
            
            if tmp.count > 1 {
                if fontFamilyName.lowercased().contains(tmp[0].lowercased())  {return (true, familyNam) }
            }
            
            if familyNam.lowercased() == fontFamilyName.lowercased() {return (true, familyNam) }
            
        }
        
        return (false, "");
    }
    
    /*
     Use this function to check font registered in device
     "Status": True/false
     "registeredFamilyname": Font family name available for current device
     */
    private func isFontalredyRegistered(fontlocalName:String)->(fontStatus:Bool, registeredFamilyname:String)? {
        if let fontName = self.registeredFontData[fontlocalName] {return (true, fontName)  }
        
        return nil
    }
    
}

//MARK: FONT ENUMS
@objc public enum UIType:Int {
    case header, title, text
    
    fileprivate func uiFontSize(fontdescriptor:FontSizeDescriptor)->Int {
        switch self {
        case  .header:
            return fontdescriptor.header
            
        case .title:
            return fontdescriptor.title
            
        case .text:
            return fontdescriptor.text
            
        }
        
    }
}

@objc public enum FontSizeDescriptor:Int {
    case small
    case medium
    case large
    case extraLarge
    
    public var header:RawValue {
        switch self {
        case .small:
            return 16
            
        case .medium:
            return 18
            
        case .large:
            return 20
            
        case .extraLarge:
            return 26
            
        }
        
    }
    
    public var title:RawValue {
        switch self {
        case .small:
            return 14
            
        case .medium:
            return 16
            
        case .large:
            return 18
            
        case .extraLarge:
            return 24
            
        }
        
    }
    
    public var text:RawValue {
        switch self {
        case .small:
            return 12
            
        case .medium:
            return 16
            
        case .large:
            return 20
            
        case .extraLarge:
            return 24
            
        }
        
    }
    
}
