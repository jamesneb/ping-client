//
//  redis.swift
//  Ping
//
//  Created by James Nebeker on 2/1/25.
//

import Foundation

import NIOCore
import NIOPosix
import RediStack
import SwiftRedis

func connectToRedis() async -> Bool {
    return await withCheckedContinuation { continuation in
        let redis = Redis()
        redis.connect(host: "localhost", port: 6379) { (redisError: NSError?) in
            if let error = redisError {
                print("Redis connection error: \(error)")
                continuation.resume(returning: false)  // Return false on failure
            } else {
                print("Connected to Redis")
                continuation.resume(returning: redis.connected)  // Return true on success
            }
        }
    }
}



