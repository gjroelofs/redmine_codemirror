module RedmineCodeMirror
  module Patches
    module TextileHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :wikitoolbar_for, :codemirror          
        end
      end


      module InstanceMethods
        def wikitoolbar_for_with_codemirror(field_id)
          heads_for_codemirror
          wikitoolbar_for_without_codemirror(field_id) + javascript_tag(%(
            CodeMirror.defineMode('#{escape_javascript "macro"}', function(config, parserConfig) {
              var macroOverlay = {
                token: function(stream, state) {
                  var ch;
                  if (stream.match('#{escape_javascript "{{"}')) {
                    while ((ch = stream.next()) != null)
                      if (ch == "}" && stream.next() == "}") {
                        stream.eat("}");
                        return "macro";
                      }
                  }
                  while (stream.next() != null && !stream.match('#{escape_javascript "{{"}', false)) {}
                  return null;
                }
              };
              return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || '#{escape_javascript "text/x-textile"}'), macroOverlay);
            });

            var editor = CodeMirror.fromTextArea(document.getElementById('#{escape_javascript "content_text"}'), {
                lineNumbers: true,
                mode: '#{escape_javascript "macro"}',
                lineWrapping: true,
                foldGutter: true,
                theme: '#{escape_javascript "neo"}',
                gutters: ['#{escape_javascript "CodeMirror-linenumbers"}', '#{escape_javascript "CodeMirror-foldgutter"}'],
                extraKeys: {
                  '#{escape_javascript "F10"}': function(cm) {
                    cm.setOption('#{escape_javascript "fullScreen"}', !cm.getOption('#{escape_javascript "fullScreen"}'));
                  },
                  '#{escape_javascript "Esc"}': function(cm) {
                    if (cm.getOption('#{escape_javascript "fullScreen"}')) cm.setOption('#{escape_javascript "fullScreen"}', false);
                  },
                  '#{escape_javascript "Ctrl-Q"}': function(cm){ 
                    cm.foldCode(cm.getCursor()); 
                  }
                }
            });
          ))
        end

        def heads_for_codemirror
          unless @heads_for_codemirror_included
            content_for :header_tags do
              javascript_include_tag(:codemirror, :plugin => 'redmine_codemirror') +
              javascript_include_tag(:textile, :plugin => 'redmine_codemirror') +
              javascript_include_tag(:fullscreen, :plugin => 'redmine_codemirror') +
              javascript_include_tag(:foldcode, :plugin => 'redmine_codemirror') +
              javascript_include_tag(:foldgutter, :plugin => 'redmine_codemirror') +
              javascript_include_tag(:textile_fold, :plugin => 'redmine_codemirror') +
              javascript_include_tag(:overlay, :plugin => 'redmine_codemirror') +
              stylesheet_link_tag(:codemirror, :plugin => 'redmine_codemirror') +
              stylesheet_link_tag(:fullscreen, :plugin => 'redmine_codemirror') +
              stylesheet_link_tag(:foldgutter, :plugin => 'redmine_codemirror') +
              stylesheet_link_tag(:redmine_syntax, :plugin => 'redmine_codemirror')+
              stylesheet_link_tag(:theme_neo, :plugin => 'redmine_codemirror')
            end
            @heads_for_codemirror_included = true
          end
        end

      end
      
    end
  end
end


unless Redmine::WikiFormatting::Textile::Helper.included_modules.include?(RedmineCodeMirror::Patches::TextileHelperPatch)
  Redmine::WikiFormatting::Textile::Helper.send(:include, RedmineCodeMirror::Patches::TextileHelperPatch)
end
