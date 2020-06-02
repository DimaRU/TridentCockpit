/////
////  CLLocation+Extensions.swift
///   Copyright © 2020 Dmitriy Borovikov. All rights reserved.
//

import CoreLocation

/*
   Latitude and Longitude in Degrees:
      ±DD.DDDD±DDD.DDDD/         (eg +12.345-098.765/)

where:

     ±DD   = three-digit integer degrees part of latitude (through -90 ~ -00 ~ +90)
     ±DDD  = four-digit integer degrees part of longitude (through -180 ~ -000 ~ +180)
     .DDDD = variable-length fraction part in degrees
     
     * Latitude is written in the first, and longitude is second.
     * The sign is always necessary for each value.
       Latitude : North="+" South="-"
       Longitude: East ="+" West ="-"
     * The integer part is a fixed length respectively.
       And padding character is "0".
       (Note: Therefor, it is shown explicitly　that the first is latitude and the second is
              longitude, from the number of figures of the integer part.)
     * It is variable-length below the decimal point.
     * "/"is a terminator.

Altitude can be added optionally.
   Latitude, Longitude (in Degrees) and Altitude:
      ±DD.DDDD±DDD.DDDD±AAA.AAA/         (eg +12.345-098.765+15.9/)
*/
 
extension CLLocation  {
    var iso6709String: String {
        String(format: "%+09.5f%+010.5f%+.0fCRSWGS_84", self.coordinate.latitude, self.coordinate.longitude, self.altitude)
    }
}
