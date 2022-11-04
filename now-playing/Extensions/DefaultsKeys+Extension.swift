import SwiftyUserDefaults

extension DefaultsKeys {
    var lastLastenedTimeStamps: DefaultsKey<[String: Double]> { .init("lastLastenedTimeStamps", defaultValue: [:])}
}
