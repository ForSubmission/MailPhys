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

class PrivateTestData {
    
    static let mboxOne = MboxGroundTruth(fileName: "mbox",
         name: "Original",
         shouldContain: [0: ["työaika", "päivä"], 1: ["like", "Giulio"], 4: ["päivä"], 31: ["Henkilöstöpalvelut"]],
         subjectShouldContain: [0: ["työaikakirjaukset", "mennessä"], 4: ["kesälomien"], 7: ["pienistä"]],
         shouldNotContain: [0: ["¶"], 1: ["Iâm"], 2: ["="], 20: ["="], 31: ["="]],
         subjectShouldNotContain: [0: ["_"], 7: ["_"]],
         nameMustBe: [0: "Päivi Kuuppelomäki", 1: "Giulio Jacucci", 7: "Päivi Kuuppelomäki"])

    static let mediumMbox = MboxGroundTruth(fileName: "mbox_med",
        name: "Medium sample",
        shouldContain: [1: ["agenda"], 2: ["GAME FACE"], 14: ["-työajankohdistusohjeet", "HY274133"], 16: ["Hyvät täydentävällä", "työskentelevät"]],
        subjectShouldContain: [0: ["tervehdys", "henkilökunnalle"], 14: [":   työaikakirjaukset 1"], 15: ["tehtävät,"], 16: ["mennessä"]],
        shouldNotContain: [0: ["="], 35: ["000_AM2PR07MB0692DB1BECC533EF8904006486110AM2PR07MB0692eurp"]],
        subjectShouldNotContain: [0: ["=", "UTF"], 14: ["="]],
        nameMustBe: [0: "Esko Ukkonen", 14: "Päivi Kuuppelomäki"])

    static let smallMbox = MboxGroundTruth(fileName: "mbox_xs",
         name: "Small sample",
         shouldContain: [1: ["pidetään"], 2: ["2115751/T31201"]],
         subjectShouldContain: [1: ["tulosesittely", "johtoryhmän"], 3: ["steeering group"]],
         shouldNotContain: [1: ["="]],
         subjectShouldNotContain: [3: ["\n"]],
         nameMustBe: [0: "Patrik Floréen", 1: "Patrik Floréen", 3: "Patrik Floréen"])

    static let tinyMbox = MboxGroundTruth(fileName: "mbox_tiny",
        name: "Tiny sample but with some http multipart at end",
        shouldContain: [0: ["#ELSEVIERHACKS"], 2: ["täyttyy"], 7: ["EXC_CRASH", "0x00007fff91b3b5ff"]],
        subjectShouldContain: [2: ["henkilökunnalle"]],
        shouldNotContain: [7: ["Message-Id: <025CFD44-E886-4A04-9194-09248ACCA6CD@cs.helsinki.fi>"]],
        subjectShouldNotContain: [1: ["="]],
        nameMustBe: [4: "Claire from BeMyApp"])
    
    static let googleMbox = MboxGroundTruth(fileName: "gmbox",
          name: "Google mail box sample",
          shouldContain: [
            3: ["Fiordaliso", "Stock"],
            17: ["https://sellercentral"],
            20: ["Eikö kirje näy", "Osoitelähde"],
            24: ["Lähetyksesi"],
            26: ["Cupertino"],
            41: ["34QDKP"],
            72: ["myös", "ympäristövaikutuksista"],
            75: ["©"],
            76: ["MailEye"]],
          subjectShouldContain: [57: ["⚠️"], 72: ["♻️"]],
          shouldNotContain: [
            3:["mimepart_586f5fb9deece_43fe668121b801736be", "=20=20"],
            7:["_label=3D", "a441d2e6"],
            26:["Part_258741698_22615050.1487254215287", "type=3D"],
            41:["Part_245425_1431568099.1489456486150", "text-align: left"],
            44:["=0A=0A=0A"],
            64:["=09=09=09", "Sin= cerely"],
            65:["=09=09=09", "Bundle ID= s"]
        ],
          subjectShouldNotContain: [:],
          nameMustBe: [57:"Claire Fourçans, ONE.org"])

}
