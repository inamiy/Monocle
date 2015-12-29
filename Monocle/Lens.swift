//
//  Lens.swift
//  Monocle
//
//  Created by to4iki on 12/20/15.
//  Copyright © 2015 to4iki. All rights reserved.
//

import Foundation

public struct Lens<S, A>: OpticType {
    
    public typealias Source = S
    
    public typealias Target = A
    
    private let getter: S -> A
    
    private let setter: (S, A) -> S
    
    public init(getter: S -> A, setter: (S, A) -> S) {
        self.getter = getter
        self.setter = setter
    }
}

// MARK: - Basic

extension Lens {
    
    /// Runs the getter on a given structure.
    public func get(s: Source) -> Target {
        return getter(s)
    }
    
    /// Runs the getter on a given structure.
    public func get(s: Source?) -> Target? {
        return s.map { (a: Source) -> Target in getter(a) }
    }
    
    /// Runs the setter on a given structure and value to yield a new structure.
    public func set(s: Source, _ t: Target) -> Source {
        return setter(s, t)
    }
    
    /// Runs the setter on a given structure and value to yield a new structure.
    public func set(s: Source?, _ t: Target) -> Source? {
        return s.map { (a: Source) -> Source in setter(a, t) }
    }
    
    /// Runs the setter on a given structure and value to yield a new structure.
    public func set(s: Source, _ t: Target?) -> Source? {
        return t.map { (b: Target) -> Source in setter(s, b) }
    }
    
    /// Runs the setter on a given structure and value to yield a new structure.
    public func set(s: Source?, _ t: Target?) -> Source? {
        if let a = s, b = t {
            return setter(a, b)
        } else {
            return nil
        }
    }
    
    /// Transform the value of the retrieved field by a function.
    public func modify(s: Source, f: Target -> Target) -> Source {
        return set(s, f(get(s)))
    }
}

// MARK: - Creator

extension Lens {
    
    /// Composes a `Lens` with the receiver.
    public func compose<T>(other: Lens<Target, T>) -> Lens<Source, T> {
        return Lens<Source, T>(
            getter: { (s: Source) -> T in
                other.get(self.get(s))
            },
            setter: { (s: Source, c: T) -> Source in
                self.set(s, other.set(self.get(s), c))
            }
        )
    }
    
    /// Creates a `Lens` that focuses on array structures.
    public func lift() -> Lens<[Source], [Target]> {
        return Lens<[Source], [Target]>(
            getter: { (ss: [Source]) -> [Target] in
                ss.map(self.get)
            },
            setter: { (ss: [Source], ts: [Target]) -> [Source] in
                zip(ss, ts).map(self.set)
            }
        )
    }
    
    /// Creates a `Lens` that focuses on two structures.
    public func split<T, B>(other: Lens<T, B>) -> Lens<(Source, T), (Target, B)> {
        return Lens<(Source, T), (Target, B)>(
            getter: { (t: (Source, T)) -> (Target, B) in
                (self.get(t.0), other.get(t.1))
            },
            setter: { (t1: (Source, T), t2: (Target, B)) -> (Source, T) in
                (self.set(t1.0, t2.0), other.set(t1.1, t2.1))
            }
        )
    }
    
    /// Creates a `Lens` that sends its input structure to both Lenses to focus on distinct subparts.
    public func fanout<B>(other: Lens<Source, B>) -> Lens<Source, (Target, B)> {
        return Lens<Source, (Target, B)>(
            getter: { (s: Source) -> (Target, B) in
                (self.get(s), other.get(s))
            },
            setter: { (s: Source, t: (Target, B)) -> Source in
                other.set(self.set(s, t.0), t.1)
            }
        )
    }
}

// MARK: - Operator

public func >>> <S, A, T>(lhs: Lens<S, A>, rhs: Lens<A, T>) -> Lens<S, T> {
    return lhs.compose(rhs)
}

public func <<< <S, A, T>(lhs: Lens<A, T>, rhs: Lens<S, A>) -> Lens<S, T> {
    return rhs.compose(lhs)
}
