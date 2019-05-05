# FONTSMANAGER 
   
# Feature
   * Download Font asynchronously.
   * Cached font for next time uses.
   * Completion Handler for asynchronous programing
   
# Installation
   pod 'FONTS'

# Usage

  1. If you have 'Fonts base url' and Fonts list.

  * Import FONTS   

   FontManager.shared.setFontBaseurl(urlString: fontBaseUrl)
   FontManager.shared.setFonts(list: fontList)
   FontManager.shared.registerAllFont()
   FontManager.shared.downloadAllFont()
   
       do {
              try  FontManager.shared.font(name: fontList[indexCount], size: 20) { (font) in
                     yourLabel?.font = font

                }

        }catch {
            debugPrint("Error = \(error.localizedDescription)")

        }
        
        
 2. If you have Fonts Url list.
 
 FontManager.shared.setfontsRemoteUrls(fontRemoteUrls: remoteUrls)
 FontManager.shared.setisuseRemoteUrls(status: true)
 FontManager.shared.registerAllFont()
 FontManager.shared.downloadAllFont()
 
    do {
              try  FontManager.shared.font(name: fontList[indexCount], size: 20) { (font) in
                     yourLabel?.font = font

                }

        }catch {
            debugPrint("Error = \(error.localizedDescription)")

        }
        
        
        
