/// A WGS 84 geographic point expressed as latitude and longitude in degrees.
///
/// This type owns coordinate representation and intrinsic bounds only.
/// Coordinate transforms, geographic predicates, distance calculations, and
/// spatial indexing belong to upper semantic and execution layers.
public struct GeographicPoint: Sendable, Hashable, Comparable {
    public let latitude: Double
    public let longitude: Double

    public init(
        latitude: Double,
        longitude: Double
    ) throws(GeographicPointError) {
        guard latitude.isFinite else {
            throw .nonFiniteLatitude
        }
        guard longitude.isFinite else {
            throw .nonFiniteLongitude
        }
        guard (-90...90).contains(latitude) else {
            throw .latitudeOutOfRange(latitude)
        }
        guard (-180...180).contains(longitude) else {
            throw .longitudeOutOfRange(longitude)
        }

        self.latitude = latitude == 0 ? 0 : latitude
        self.longitude = longitude == 0 ? 0 : longitude
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.latitude != rhs.latitude {
            return lhs.latitude < rhs.latitude
        }
        return lhs.longitude < rhs.longitude
    }
}
