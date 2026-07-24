/// A three-dimensional WGS 84 position.
///
/// Height is measured in meters from the WGS 84 reference ellipsoid. It is
/// intentionally not an optional property of `GeographicPoint`, so two- and
/// three-dimensional values retain distinct identity and indexing semantics.
/// Orthometric height, mean-sea-level elevation, and vertical-datum
/// transformations belong to upper geographic layers.
public struct GeographicPosition: Sendable, Hashable, Comparable {
    public let point: GeographicPoint
    public let ellipsoidalHeightInMeters: Double

    public init(
        point: GeographicPoint,
        ellipsoidalHeightInMeters: Double
    ) throws(GeographicPositionError) {
        guard ellipsoidalHeightInMeters.isFinite else {
            throw .nonFiniteEllipsoidalHeight
        }
        self.point = point
        self.ellipsoidalHeightInMeters =
            ellipsoidalHeightInMeters == 0 ? 0 : ellipsoidalHeightInMeters
    }

    public init(
        latitude: Double,
        longitude: Double,
        ellipsoidalHeightInMeters: Double
    ) throws(GeographicPositionError) {
        let point: GeographicPoint
        do {
            point = try GeographicPoint(
                latitude: latitude,
                longitude: longitude
            )
        } catch let error {
            throw .invalidPoint(error)
        }
        try self.init(
            point: point,
            ellipsoidalHeightInMeters: ellipsoidalHeightInMeters
        )
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.point != rhs.point {
            return lhs.point < rhs.point
        }
        return lhs.ellipsoidalHeightInMeters
            < rhs.ellipsoidalHeightInMeters
    }
}
