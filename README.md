# eidReader

<table>
<thead>
<tr>
<th width=50%>English</th>
<th>Nederlands</th>
</tr>
</thead>
<tr>
<td>A macOS application to read information from Belgian electronic ID cards (also known as beID or belgian eID) without the need to install additional drivers or java software.

Following information is available:
- Profile picture
- First and last name
- Sex
- Place of birth and birthday
- Home address (textual and visual using maps)
- Identification number of the National Register
- Card number
- Validity period

All information can be saved and/or printed.

The application runs in an App Sandbox (without internet connection) and is open source. So you can be sure that it does not leak confidential information to any party.
</td><td>Met deze kaartlezer kan je eenvoudig de informatie van een Belgische identiteitskaart uitlezen. Er is geen driver of java vereist.

Volgende informatie is beschikbaar:
- Profielfoto
- Naam, Achternaam
- Geslacht
- Geboorteplaats, -datum
- Woonplaats (tekstueel en via kaarten)
- Rijksregisternummer
- Kaartnummer
- Geldigheidsperiode van de kaart
- Afhaallocatie

Alle informatie kan opgeslagen en/of afgedrukt worden.

Deze applicatie maakt gebruik van Apples "App Sandbox" technologie, heeft geen netwerktoegang en is volledig open source. Je kan er dus zeker van zijn dat het geen vertrouwelijke informatie doorgeeft (of lekt) aan andere partijen.</td>
</tr>
</table>

![screenshot](screenshot.png)

## Technology

<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat" alt="Swift" /></a>

This application uses Apple's standard `CryptoTokenKit` framework to communicate with the smartcard reader and is written completely in Swift 3.

## Installation

Choose one of the following providers:

| Apple | GitHub |
| ----- | ------ |
| <a href="https://itunes.apple.com/us/app/eidreader/id1190651975?l=nl&ls=1&mt=12"><img src="https://cdn.rawgit.com/Dev1an/eID-Reader/master/Download_on_the_App_Store_Badge_US-UK.svg" alt="Download on the App Store Badge" /></a> | Download via [GitHub](https://github.com/Dev1an/eID-Reader/releases/latest) |
