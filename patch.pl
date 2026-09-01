my $file = "/home/egarcia/Zero/nixos-config/modules/sicos/hyprland/config-files/quickshell/components/controlcenter.nix";
open my $in, '<', $file or die $!;
my $content = do { local $/; <$in> };
close $in;

$content =~ s/let matchStr = name \+ " " \+ bin \+ " " \+ iconName;.*?if \(matchStr.indexOf\("vlc"\) !== -1\) return "image:\/\/icon\/vlc";\s+spacing: 12\s+Item \{/let matchStr = name + " " + bin + " " + iconName;
                                            if (matchStr.indexOf("spotify") !== -1) return "image:\/\/icon\/spotify";
                                            if (matchStr.indexOf("firefox") !== -1) return "image:\/\/icon\/firefox";
                                            if (matchStr.indexOf("chrome") !== -1) return "image:\/\/icon\/google-chrome";
                                            if (matchStr.indexOf("brave") !== -1) return "image:\/\/icon\/brave";
                                            if (matchStr.indexOf("discord") !== -1) return "image:\/\/icon\/discord";
                                            if (matchStr.indexOf("telegram") !== -1) return "image:\/\/icon\/telegram";
                                            if (matchStr.indexOf("mpv") !== -1) return "image:\/\/icon\/mpv";
                                            if (matchStr.indexOf("vlc") !== -1) return "image:\/\/icon\/vlc";
                                            
                                            if (iconName && iconName !== "") return "image:\/\/icon\/" + iconName;
                                            if (bin && bin !== "") return "image:\/\/icon\/" + bin;
                                            
                                            return "image:\/\/icon\/audio-x-generic";
                                        }
                                        opacity: modelData.audio.muted ? 0.5 : 1.0
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: modelData.audio.muted = !modelData.audio.muted
                                        }
                                    }
                                    
                                    Text {
                                        text: {
                                            let p = modelData.properties;
                                            return p ? (p["application.name"] || p["media.name"] || modelData.name) : modelData.name;
                                        }
                                        color: "#\$\{c.base05\}"
                                        font.family: "\$\{fontName\}"
                                        font.pixelSize: 13
                                        Layout.preferredWidth: 80
                                        Layout.minimumWidth: 80
                                        Layout.maximumWidth: 80
                                        elide: Text.ElideRight
                                    }
                                    
                                    Item {/gs;

open my $out, '>', $file or die $!;
print $out $content;
close $out;
