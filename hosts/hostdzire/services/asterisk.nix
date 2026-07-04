{ lib, pkgs, ... }:
let
  sipDomain = "sip.diffumist.dn42";
  dn42Ipv4 = "172.22.64.66";
  dn42Ipv6 = "fd22:1056:95a4:2::1";
  tel42Resolvers = [
    "172.21.80.224"
    "fdfa:6ded:ae4::1"
  ];
  fallbackResolvers = [
    "1.0.0.1"
    "8.8.4.4"
    "2606:4700:4700::1001"
    "2001:4860:4860::8844"
  ];
in
{
  networking.nameservers = lib.mkBefore (tel42Resolvers ++ fallbackResolvers);

  networking.firewall.extraInputRules = ''
    ip saddr 172.20.0.0/14 udp dport 5060 accept
    ip saddr 172.20.0.0/14 udp dport 10000-10100 accept
    ip6 saddr fd00::/8 udp dport 5060 accept
    ip6 saddr fd00::/8 udp dport 10000-10100 accept
  '';

  environment.etc."tel42verifier/enum_config.yaml".text = ''
    default:
      domain: "tel.dn42"
      nameservers:
        - "172.21.80.224"
        - "fdfa:6ded:ae4::1"
      dnssec: true
  '';

  services.asterisk = {
    enable = true;
    confFiles = {
      "modules.conf" = ''
        [modules]
        autoload=yes
        load = res_pjsip_endpoint_identifier_anonymous.so
      '';

      "pjsip.conf" = ''
        [global]
        type=global
        endpoint_identifier_order=ip,username,anonymous
        user_agent=${sipDomain}

        [transport-udp-v4]
        type=transport
        protocol=udp
        bind=${dn42Ipv4}

        [transport-udp-v6]
        type=transport
        protocol=udp
        bind=${dn42Ipv6}

        [anonymous]
        type=endpoint
        context=from-tel42
        disallow=all
        allow=ulaw,alaw,g722
        direct_media=no
        allow_subscribe=no
      '';

      "extensions.conf" = ''
        [general]
        static=yes
        writeprotect=yes

        [from-tel42]
        exten => _+X!,1,NoOp(Inbound Telephony42 call to ''${EXTEN} from ''${CALLERID(all)})
          same => n,Goto(tel42-verify,''${EXTEN},1)
        exten => _X!,1,NoOp(Inbound Telephony42 call to ''${EXTEN} from ''${CALLERID(all)})
          same => n,Goto(tel42-verify,+''${EXTEN},1)
        exten => s,1,Hangup(21)
        exten => i,1,Hangup(21)

        [tel42-verify]
        exten => _+X!,1,Set(CALLERID_NUM=''${CALLERID(num)})
          same => n,Set(REAL_SRC=''${CHANNEL(pjsip,remote_addr)})
          same => n,AGI(tel42verifier,''${CALLERID_NUM},''${REAL_SRC})
          same => n,GotoIf($["''${ENUM_VERIFY_RESULT}" = "PASS"]?trusted,1)
          same => n,Goto(reject,1)

        exten => trusted,1,NoOp(Verified Telephony42 caller ''${CALLERID_NUM})
          same => n,ExecIf($["''${ENUM_CID_NAME}" != ""]?Set(CALLERID(name)=''${ENUM_CID_NAME}))
          same => n,Goto(inbox,600,1)

        exten => reject,1,NoOp(Rejected caller because ''${ENUM_VERIFY_RESULT})
          same => n,Hangup(21)

        [inbox]
        exten => 600,1,Ringing()
          same => n,Playback(hello)
          same => n,SayUnixTime()
          same => n,Playback(demo-thanks)
          same => n,VoiceMail(600@default,u)
          same => n,Hangup()

        [lab]
        exten => 600,1,Answer()
          same => n,Playback(demo-echotest)
          same => n,Echo()
          same => n,Playback(demo-echodone)
          same => n,Hangup()

        [outbound-tel42]
        exten => _042X!,1,Goto(outbound-tel42,+''${EXTEN},1)
        exten => _+042X!,1,NoOp(Resolving Telephony42 destination ''${EXTEN})
          same => n,Set(TEL42_TARGET=''${ENUMLOOKUP(''${EXTEN},pjsip,,1,tel.dn42)})
          same => n,GotoIf($["''${TEL42_TARGET}" != ""]?dial)
          same => n,Hangup(3)
          same => n(dial),Dial(PJSIP/''${TEL42_TARGET},60)
          same => n,Hangup()
      '';

      "enum.conf" = ''
        [general]
        search => tel.dn42
      '';

      "voicemail.conf" = ''
        [general]
        format = wav49|gsm
        maxsecs = 180

        [default]
        600 => 0642,DN42 Inbox
      '';

      "rtp.conf" = ''
        [general]
        rtpstart=10000
        rtpend=10100
        strictrtp=yes
      '';
    };
  };

  systemd.services.asterisk = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    preStart = lib.mkAfter ''
      install -d -m755 /var/lib/asterisk/agi-bin
      ln -sfn ${pkgs.tel42verifier}/bin/tel42verifier /var/lib/asterisk/agi-bin/tel42verifier
    '';
  };
}
