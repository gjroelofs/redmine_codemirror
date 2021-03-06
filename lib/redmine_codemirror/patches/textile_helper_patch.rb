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

          url = "#{Redmine::Utils.relative_url_root}/help/#{current_language.to_s.downcase}/wiki_syntax.html"

          # wikitoolbar_for_without_codemirror(field_id) +
          javascript_tag(%(
            CodeMirror.defineMode("macro", function(config, parserConfig) {
              var macroOverlay = {
                token: function(stream, state) {
                  var ch;
                  if (stream.match("{{")) {
                    while ((ch = stream.next()) != null)
                      if (ch == "}" && stream.next() == "}") {
                        stream.eat("}");
                        return "keyword";
                      }
                  } else if (stream.match("TODO")) {
                    return "todo";
                  }
                  while (stream.next() != null && !stream.match("{{", false) && !stream.match("TODO", false)) {}
                  return null;
                }
              };
              return CodeMirror.overlayMode(CodeMirror.getMode(config, parserConfig.backdrop || "text/x-textile"), macroOverlay);
            });

            var area = document.getElementById("#{field_id}");
            var editor = CodeMirror.fromTextArea(area, {
                lineNumbers: true,
                mode: "macro",
                lineWrapping: true,
                foldGutter: true,
                theme: "neo",
                gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
                extraKeys: {
                 "F10": function(cm) {
                    cm.setOption("fullScreen", !cm.getOption("fullScreen"));
                  },
                  "Esc": function(cm) {
                    if (cm.getOption("fullScreen")) cm.setOption("fullScreen", false);
                  },
                  "Ctrl-Q": function(cm){ 
                    cm.foldCode(cm.getCursor()); 
                  }
                }
            });
            
            area.id = "old_#{field_id}";
            editor.getInputField().id = "#{field_id}";

            // To make sure the TextArea is updated for the preview function, TODO: hook into preview logic
            editor.on('change',function(cm){
              cm.save();
            });
		
	    // FIX: sizing issue when div was first hidden
            editor.on('focus', function(){
		editor.refresh();
	    });

            var editorWrapper = editor.getWrapperElement();

            $(editorWrapper).resizable({
              resize: function() {
                editor.setSize($(this).width(), $(this).height());
                editor.refresh();
              }
            });

           fullscreenButton(editorWrapper, editor);
            var wikiToolbar = new jsToolBar(editor);
            wikiToolbar.setHelpLink('#{escape_javascript url}');
            wikiToolbar.draw();
          ))
        end

        def heads_for_codemirror
          unless @heads_for_codemirror_included
            content_for :header_tags do
              javascript_include_tag(:jstoolbar_codemirror, :plugin => 'redmine_codemirror') +
              javascript_include_tag(:jstoolbar_textile, :plugin => 'redmine_codemirror') +
              javascript_include_tag("jstoolbar/lang/jstoolbar-#{current_language.to_s.downcase}") +
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
              stylesheet_link_tag(:theme_neo, :plugin => 'redmine_codemirror') +
              stylesheet_link_tag('jstoolbar')
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
