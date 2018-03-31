//
// Copyright (c) 2018 ANONYMISED
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import Foundation

class PublicTestData {
    static let mboxOne = MboxGroundTruth(fileName: "mbox_one",
                                         name: "iCloudSampleOne",
                                         shouldContain: [0: ["m●●●●●●●@icloud.com", "imap"], 1: ["mactuki18@icloud.com", "January"], 2: ["devices", "Support"], 3: ["mactuki18@icloud.com", "iCloud"]],
                                         subjectShouldContain: [0: ["app‑specific", "ID"], 1: ["iCloud", "MacBook"], 2: ["iCloud"]],
                                         shouldNotContain: [0: ["------=_Part_4366391_69134150.1516117303405", "------=_Part_4366391_69134150.1516117303405", "sans-serif"], 1: ["------=_Part_4210549_575793530.1516116707197", "text-decoration", "http://outsideapple.apple.com"], 2: ["------=_Part_2050414_1824200049.1516116693006", "=3D=3D=3D=3D=3D=3D=3D=3D=3D=3D", "line-height"], 3: ["------=_Part_2024754_1995676627.1516116693181", "a.big-button", "Helvetica Neue, Helvetica, Arial"]],
                                         subjectShouldNotContain: [:],
                                         nameMustBe: [0: "Apple", 1: "Apple", 2: "iCloud"])
}
