import XCTest
@testable import XmlParserDynamic

private let text = """
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="BookID">
  <metadata xmlns:opf="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <language>ja</language>
    <dc:publisher>電子書籍部(米光一成)</dc:publisher>
    <language mm="0">ja2</language>
    <dc:creator>電子書籍部</dc:creator>
    <dc:date>2010-11-30</dc:date>
    <dc:title>サンプル電書</dc:title>
    <dc:identifier id="BookID" opf:scheme="URL">http://lv99.com/densho/ebooksdensho_sample2010/11/30</dc:identifier>
    <dc:contributor>構成・テキスト：XXX
グラフィックス：XXX
写真：XXX</dc:contributor>
    <meta name="cover" content="imgcover"/>
  </metadata>
  <metadata xmlns:opf="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <language>ja3</language>
    <dc:publisher>電子書籍部(米光一成)</dc:publisher>
    <language>ja4</language>
    <dc:creator>電子書籍部</dc:creator>
    <dc:date>2010-11-30</dc:date>
    <dc:title>サンプル電書</dc:title>
    <dc:identifier id="BookID" opf:scheme="URL">http://lv99.com/densho/ebooksdensho_sample2010/11/30</dc:identifier>
    <dc:contributor>構成・テキスト：XXX
グラフィックス：XXX
写真：XXX</dc:contributor>
    <meta name="cover" content="imgcover"/>
  </metadata>
  <manifest>
    <item id="imgcover" href="img/cover.jpg" media-type="image/jpeg"/>
    <item id="imgcapture" href="img/capture.jpg" media-type="image/jpeg"/>
    <item id="cover" href="text/cover.html" media-type="application/xhtml+xml"/>
    <item id="chap00_maegaki" href="text/00_maegaki.html" media-type="application/xhtml+xml"/>
    <item id="chap01_genkou" href="text/01_genkou.html" media-type="application/xhtml+xml"/>
    <item id="chap02_genkou" href="text/02_genkou.html" media-type="application/xhtml+xml"/>
    <item id="chap03_atogaki" href="text/03_atogaki.html" media-type="application/xhtml+xml"/>
    <item id="chap04_writers" href="text/04_writers.html" media-type="application/xhtml+xml"/>
    <item id="css" href="css/miraitext.css" media-type="text/css"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="okuduke" href="text/okuduke.html" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="cover"/>
    <itemref idref="chap00_maegaki"/>
    <itemref idref="chap01_genkou"/>
    <itemref idref="chap02_genkou"/>
    <itemref idref="chap03_atogaki"/>
    <itemref idref="chap04_writers"/>
    <itemref idref="okuduke"/>
  </spine>
</package>
"""

final class XmlParserDynamicTests: XCTestCase {
    func testExample() {
        let xml = XmlParserDynamic(data: text.data(using: .utf8)!)
        let exception = self.expectation(description: "xml")
        xml.package.metadata.language.getElements(callback: { (result) in
            switch result {

            case .success(let element):
                XCTAssertEqual(element.elements, [
                    Element(character: "ja", xPath: "/package[1]/metadata[1]/language[1]"),
                    Element(character: "ja2", xPath: "/package[1]/metadata[1]/language[2]"),
                    Element(character: "ja3", xPath: "/package[1]/metadata[2]/language[1]"),
                    Element(character: "ja4", xPath: "/package[1]/metadata[2]/language[2]"),
                ])

                exception.fulfill()
            case .failure(_):
                XCTFail()
            }
        })
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
