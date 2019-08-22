import 'package:test/test.dart';
import 'package:sip_ua/src/Grammar.dart';
import 'package:sip_ua/src/URI.dart';
import 'package:sip_ua/src/NameAddrHeader.dart';

var testFunctions = [
  () => test("Parser: Host => [ domain, ipv4, ipv6 ].", () {
        var data = Grammar.parse('www.google.com', 'host');
        expect(data['host_type'], 'domain');

        data = Grammar.parse('www.163.com', 'host');
        expect(data['host_type'], 'domain');

        data = Grammar.parse('myhost123', 'host');
        expect(data['host_type'], 'domain');

        data = Grammar.parse('localhost', 'host');
        expect(data['host_type'], 'domain');

        data = Grammar.parse('1.2.3.4.bar.qwe-asd.foo', 'host');
        expect(data['host_type'], 'domain');

        data = Grammar.parse('192.168.0.1', 'host');
        expect(data['host_type'], 'IPv4');

        data = Grammar.parse('127.0.0.1', 'host');
        expect(data['host_type'], 'IPv4');

        data = Grammar.parse('[::1]', 'host');
        expect(data['host_type'], 'IPv6');

        data = Grammar.parse('[1:0:fF::432]', 'host');
        expect(data['host_type'], 'IPv6');
      }),
  () => test("Parser: URI.", () {
        const uriData =
            'siP:%61liCE@versaTICA.Com:6060;TRansport=TCp;Foo=ABc;baz?X-Header-1=AaA1&X-Header-2=BbB&x-header-1=AAA2';
        URI uri = URI.parse(uriData);
        print('uriData => ' + uriData);
        print('uri => ' + uri.toString());
        expect(uri.scheme, 'sip');
        expect(uri.user, 'aliCE');
        expect(uri.port, 6060);
        expect(uri.hasParam('transport'), true);
        expect(uri.hasParam('nooo'), false);
        expect(uri.getParam('transport'), 'tcp');

        expect(uri.getParam('foo'), 'ABc');
        expect(uri.getParam('baz'), null);
        expect(uri.getParam('nooo'), null);
        expect(uri.getHeader('x-header-1'), [ 'AaA1', 'AAA2' ]);
        expect(uri.getHeader('X-HEADER-2'), [ 'BbB' ]);
        expect(uri.getHeader('nooo'), null);
        print('uri => ' + uri.toString());
        expect(uri.toString(),
            'sip:aliCE@versatica.com:6060;transport=tcp;foo=ABc;baz?X-Header-1=AaA1&X-Header-1=AAA2&X-Header-2=BbB');
        expect(uri.toAor(show_port: true), 'sip:aliCE@versatica.com:6060');

        // Alter data.
        uri.user = 'Iñaki:PASSWD';
        expect(uri.user, 'Iñaki:PASSWD');
        expect(uri.deleteParam('foo'), 'ABc');
        expect(uri.deleteHeader('x-header-1'), [ 'AaA1', 'AAA2' ]);
        uri.deleteHeader('x-header-1');
        expect(uri.toString(),
            'sip:I%C3%B1aki:PASSWD@versatica.com:6060;transport=tcp;baz?X-Header-2=BbB');
        expect(uri.toAor(), 'sip:I%C3%B1aki:PASSWD@versatica.com');
        uri.clearParams();
        uri.clearHeaders();
        uri.port = null;
        expect(uri.toString(), 'sip:I%C3%B1aki:PASSWD@versatica.com');
        expect(uri.toAor(), 'sip:I%C3%B1aki:PASSWD@versatica.com');
      }),
  () => test("Parser: NameAddr with token display_name.", () {
        const data =
            'Foo    Foo Bar\tBaz<SIP:%61liCE@versaTICA.Com:6060;TRansport=TCp;Foo=ABc;baz?X-Header-1=AaA1&X-Header-2=BbB&x-header-1=AAA2>;QWE=QWE;ASd';
        NameAddrHeader name = NameAddrHeader.parse(data);
        print('name => ' + name.toString());

        expect(name.display_name, 'Foo Foo Bar Baz');
      }),
  () => test("Parser: NameAddr with no space between DQUOTE and LAQUOT.", () {
        const data =
            '"Foo"<SIP:%61liCE@versaTICA.Com:6060;TRansport=TCp;Foo=ABc;baz?X-Header-1=AaA1&X-Header-2=BbB&x-header-1=AAA2>;QWE=QWE;ASd';
        NameAddrHeader name = NameAddrHeader.parse(data);
        print('name => ' + name.toString());

        expect(name.display_name, 'Foo');
      }),
  () => test("Parser: NameAddr with no space between DQUOTE and LAQUOT", () {
        const data =
            '<SIP:%61liCE@versaTICA.Com:6060;TRansport=TCp;Foo=ABc;baz?X-Header-1=AaA1&X-Header-2=BbB&x-header-1=AAA2>;QWE=QWE;ASd';
        NameAddrHeader name = NameAddrHeader.parse(data);
        print('name => ' + name.toString());

        expect(name.display_name, null);
      }),
  () => test("Parser: NameAddr.", () {
        const data =
            '  "Iñaki ðđøþ foo \\"bar\\" \\\\\\\\ \\\\ \\\\d \\\\\\\\d \\\\\' \\\\\\"sdf\\\\\\""  ' +
                '<SIP:%61liCE@versaTICA.Com:6060;TRansport=TCp;Foo=ABc;baz?X-Header-1=AaA1&X-Header-2=BbB&x-header-1=AAA2>;QWE=QWE;ASd';
        NameAddrHeader name = NameAddrHeader.parse(data);
        print('name => ' + name.toString());
        expect(name.display_name,
            'Iñaki ðđøþ foo \\"bar\\" \\\\\\\\ \\\\ \\\\d \\\\\\\\d \\\\\' \\\\\\"sdf\\\\\\"');
      }),
  () => test("Parser: multiple Contact.", () {
        const data =
            '"Iñaki @ł€" <SIP:+1234@ALIAX.net;Transport=WS>;+sip.Instance="abCD", sip:bob@biloxi.COM;headerParam, <sip:DOMAIN.com:5>';
        var contacts = Grammar.parse(data, 'Contact');
        print('contacts => ' + contacts.toString());

        expect(contacts.length, 3);
        var c1 = contacts[0]['parsed'];
        var c2 = contacts[1]['parsed'];
        var c3 = contacts[2]['parsed'];

        // Parsed data.
        expect(c1.display_name, 'Iñaki @ł€');
        expect(c1.hasParam('+sip.instance'), true);
        expect(c1.hasParam('nooo'), false);
        expect(c1.getParam('+SIP.instance'), '"abCD"');
        expect(c1.getParam('nooo'), null);

        expect(c1.uri.scheme, 'sip');
        expect(c1.uri.user, '+1234');
        expect(c1.uri.host, 'aliax.net');
        expect(c1.uri.port, null);
        expect(c1.uri.getParam('transport'), 'ws');
        expect(c1.uri.getParam('foo'), null);
        expect(c1.uri.getHeader('X-Header'), null);
        expect(c1.toString(),
            '"Iñaki @ł€" <sip:+1234@aliax.net;transport=ws>;+sip.instance="abCD"');

        // Alter data.
        c1.display_name = '€€€';
        expect(c1.display_name, '€€€');
        c1.uri.user = '+999';
        expect(c1.uri.user, '+999');
        c1.setParam('+sip.instance', '"zxCV"');
        expect(c1.getParam('+SIP.instance'), '"zxCV"');
        c1.setParam('New-Param', null);
        expect(c1.hasParam('NEW-param'), true);
        c1.uri.setParam('New-Param', null);
        expect(c1.toString(),
            '"€€€" <sip:+999@aliax.net;transport=ws;new-param>;+sip.instance="zxCV";new-param');

        // Parsed data.
        expect(c2.display_name, null);
        expect(c2.hasParam('HEADERPARAM'), true);
        expect(c2.uri.scheme, 'sip');
        expect(c2.uri.user, 'bob');
        expect(c2.uri.host, 'biloxi.com');
        expect(c2.uri.port, null);
        expect(c2.uri.hasParam('headerParam'), false);
        expect(c2.toString(), '<sip:bob@biloxi.com>;headerparam');

        // Alter data.
        c2.display_name = '@ł€ĸłæß';
        expect(c2.toString(), '"@ł€ĸłæß" <sip:bob@biloxi.com>;headerparam');

        // Parsed data.
        expect(c3.display_name, null);
        expect(c3.uri.scheme, 'sip');
        expect(c3.uri.user, null);
        expect(c3.uri.host, 'domain.com');
        expect(c3.uri.port, 5);
        expect(c3.uri.hasParam('nooo'), false);
        expect(c3.toString(), '<sip:domain.com:5>');

        // Alter data.
        c3.uri.setParam('newUriParam', 'zxCV');
        c3.setParam('newHeaderParam', 'zxCV');
        expect(c3.toString(),
            '<sip:domain.com:5;newuriparam=zxCV>;newheaderparam=zxCV');
      }),
  () => test("Parser: Via.", () {
        const data =
            'SIP /  3.0 \r\n / UDP [1:ab::FF]:6060 ;\r\n  BRanch=1234;Param1=Foo;paRAM2;param3=Bar';
        var via = Grammar.parse(data, 'Via');

        print('via => ' + via.toString());

        expect(via.protocol, 'SIP');
        expect(via.transport, 'UDP');
        expect(via.host, '[1:ab::FF]');
        expect(via.host_type, 'IPv6');
        expect(via.port, 6060);
        expect(via.branch, '1234');
        expect(via.params, { 'branch': '1234', 'param1': 'Foo', 'param2': null, 'param3': 'Bar' });
      }),
  () => test("Parser: CSeq.", () {
        const data = '123456  CHICKEN';
        var cseq = Grammar.parse(data, 'CSeq');

        print('cseq => ' + cseq.toString());

        expect(cseq.value, 123456);
        expect(cseq.method, 'CHICKEN');
      }),
  () => test("Parser: authentication challenge.", () {
        const data =
            'Digest realm =  "[1:ABCD::abc]", nonce =  "31d0a89ed7781ce6877de5cb032bf114", qop="AUTH,autH-INt", algorithm =  md5  ,  stale =  TRUE , opaque = "00000188"';
        var auth = Grammar.parse(data, 'challenge');

        print('auth => ' + auth.toString());

        //TODO:  fix other_auth_param parse;

        expect(auth.realm, '[1:ABCD::abc]');
        expect(auth.nonce, '31d0a89ed7781ce6877de5cb032bf114');
        expect(auth.qop[0], 'auth');
        expect(auth.qop[1], 'auth-int');
        expect(auth.algorithm, 'MD5');
        expect(auth.stale, true);
        expect(auth.opaque, '00000188');
      }),
  () => test("Parser: Event.", () {
        const data = 'Presence;Param1=QWe;paraM2';
        var event = Grammar.parse(data, 'Event');

        print('event => ' + event.toString());

        expect(event.event, 'presence');
        expect(event.params['param1'], 'QWe');
        expect(event.params['param2'], null);
      }),
  () => test("Parser: Session-Expires.", () {
        var data, session_expires;

        data = '180;refresher=uac';
        session_expires = Grammar.parse(data, 'Session_Expires');

        print('session_expires => ' + session_expires.toString());

        expect(session_expires.expires, 180);
        expect(session_expires.refresher, 'uac');

        data = '210  ;   refresher  =  UAS ; foo  =  bar';
        session_expires = Grammar.parse(data, 'Session_Expires');

        print('session_expires => ' + session_expires.toString());

        expect(session_expires.expires, 210);
        expect(session_expires.refresher, 'uas');
      }),
  () => test("Parser: Reason.", () {
        var data, reason;

        data = 'SIP  ; cause = 488 ; text = "Wrong SDP"';
        reason = Grammar.parse(data, 'Reason');

        print('reason => ' + reason.toString());

        expect(reason.protocol, 'sip');
        expect(reason.cause, 488);
        expect(reason.text, 'Wrong SDP');

        data = 'ISUP; cause=500 ; LALA = foo';
        reason = Grammar.parse(data, 'Reason');

        print('reason => ' + reason.toString());

        expect(reason.protocol, 'isup');
        expect(reason.cause, 500);
        expect(reason.text, null);
        expect(reason.params['lala'], 'foo');
      }),
  () => test("Parser: Refer-To.", () {
        var data, parsed;

        data = 'sip:alice@versatica.com';
        parsed = Grammar.parse(data, 'Refer_To');

        print('refer-to => ' + parsed.toString());

        expect(parsed.uri.scheme, 'sip');
        expect(parsed.uri.user, 'alice');
        expect(parsed.uri.host, 'versatica.com');

        data =
            '<sip:bob@versatica.com?Accept-Contact=sip:bobsdesk.versatica.com>';
        parsed = Grammar.parse(data, 'Refer_To');

        print('refer-to => ' + parsed.toString());

        expect(parsed.uri.scheme, 'sip');
        expect(parsed.uri.user, 'bob');
        expect(parsed.uri.host, 'versatica.com');
        expect(parsed.uri.hasHeader('Accept-Contact'), true);
      }),
  () => test("Parser: Replaces.", () {
        var parsed;
        const data =
            '5t2gpbrbi72v79p1i8mr;to-tag=03aq91cl9n;from-tag=kun98clbf7';

        parsed = Grammar.parse(data, 'Replaces');

        print('replaces => ' + parsed.toString());

        expect(parsed.call_id, '5t2gpbrbi72v79p1i8mr');
        expect(parsed.to_tag, '03aq91cl9n');
        expect(parsed.from_tag, 'kun98clbf7');
      })
];

void main() {
  testFunctions.forEach((func) => func());
}
