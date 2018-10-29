//
//  SourceEditorCommand.swift
//  Quick Add
//
//  Created by Sidney de Koning on 19/10/2016.
//  Copyright © 2016 Sidney de Koning. All rights reserved.
//

import Foundation
import XcodeKit

/// 3. Add Distinction between Swift and Objective-C files
enum ContentType: String {
    case swift = "public.swift-source"
    case objc = "public.objective-c-source"
}

extension String {
    
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }

    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(start, offsetBy: r.upperBound - r.lowerBound)
        return String(self[(start..<end)])
    }
    
    subscript (r: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(start, offsetBy: r.upperBound - r.lowerBound)
        return String(self[(start...end)])
    }
}


class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        
        /// 1. Fail fast if there is no text selected at all or there is no text in the file
        guard let textRange = invocation.buffer.selections.firstObject as? XCSourceTextRange, invocation.buffer.lines.count > 0 else {
            // docs tell us to pass an error, but we dont really need it
            completionHandler(nil)
            return
        }
        
        /// 2. For now - make sure we only implement a function in Swift source files.
        if invocation.buffer.contentUTI == ContentType.swift.rawValue {
            
            if invocation.commandIdentifier == "quickAdd.AddMethod" {
                self.transform(on: textRange, with: invocation)
            }
        }
        
        completionHandler(nil)
    }
    
    
    
    /// 4. Transform string in a range
    func transform(on range: XCSourceTextRange, with invocation: XCSourceEditorCommandInvocation) {
        
        for index in range.start.line ... range.end.line {
            guard let line = invocation.buffer.lines[index] as? String else { break }
            
            // The text we selected and want to make an method implementation of
            let selectedSourceCode = line[range.start.column...range.end.column].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create new method at end of file, two lines up
            let insertionLine = invocation.buffer.lines.count - 1
            let signature = self.createMethodAndComment(name: selectedSourceCode)
            invocation.buffer.lines.insert(signature, at: insertionLine)

			// We need to find the current identation
			// Find the next closing brace
			// Insert method after next closing brace with some padding
            
            // Set cursor to insertion point so we can tab
            let cursor: XCSourceTextPosition = XCSourceTextPosition(line: insertionLine, column: 1)
            let updatedBuffer = XCSourceTextRange(start: cursor, end: cursor)
            
            invocation.buffer.selections.setArray([updatedBuffer])
            // TODO: Do a complete parsing of real method signature, not only piece of text
        }
    }
    
    /// 5. Create and actual method from a string
    func create(methodName: String) -> String {
        
        let method = "\n\t\(self.placeholder("accesslevel")) func \(methodName)() -> \(self.placeholder("ReturnType")) {\n\t\t\(self.placeholder("code"))\n\t}"
        
        return method
    }
    
    /// 6. Create comment
    func createComment(methodName: String) -> String {
        let method = "\n\t/// \(methodName) - Description: \(self.placeholder("description"))"
        
        return method
    }
    
    /// 7. Bundle method and comment
    func createMethodAndComment(name: String) -> String {
        return self.createComment(methodName: name) + self.create(methodName: name)
    }
    
    /// 8. Create placeholders.
    /// Unfortunately this cannot be done on one line because it directly creates a placeholder from it
    func placeholder(_ name:String) -> String {
        let lhs = "<#"
        let rhs = "#>"
        return lhs + name + rhs
    }
    
}
