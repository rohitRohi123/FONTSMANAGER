//  ERRORS.swift
//  CreatedApp


import Foundation

enum APIError:Error {
    case Network, InvalidUrl, InvalidResponse, ParsingError;
    
}

enum FontError:Error {
    case FontnotAvailable ;
}

enum  HeaderError:Error {
    case Uninitialized
}
