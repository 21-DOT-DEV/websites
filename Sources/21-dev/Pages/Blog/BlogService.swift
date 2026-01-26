//
//  BlogService.swift
//  21-DOT-DEV/BlogService.swift
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Service for loading and managing blog posts
struct BlogService {
    private static let blogDirectory = "Resources/21-dev/blog"
    
    /// Load all blog posts from the blog directory
    static func loadAllPosts() -> [BlogPost] {
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let blogPath = "\(currentDirectory)/\(blogDirectory)"
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: blogPath)
            let markdownFiles = files.filter { $0.hasSuffix(".md") }
            
            var posts: [BlogPost] = []
            
            for file in markdownFiles {
                let filePath = "\(blogPath)/\(file)"
                if let content = try? String(contentsOfFile: filePath, encoding: .utf8),
                   let post = try? BlogPost.parse(from: content) {
                    posts.append(post)
                }
            }
            
            // Sort by date (newest first)
            return posts.sorted { $0.metadata.parsedDate > $1.metadata.parsedDate }
        } catch {
            return []
        }
    }
    
    /// Load a specific blog post by slug
    static func loadPost(slug: String) -> BlogPost? {
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let filePath = "\(currentDirectory)/\(blogDirectory)/\(slug).md"
        
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8),
              let post = try? BlogPost.parse(from: content) else {
            return nil
        }
        
        return post
    }
}
