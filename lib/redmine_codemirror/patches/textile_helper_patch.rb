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
            var editor = CodeMirror.fromTextArea(document.getElementById('#{escape_javascript "content_text"}'), {
                lineNumbers: true,
                mode: '#{escape_javascript "text/x-textile"}'
            });
          ))
        end

        def heads_for_codemirror
          unless @heads_for_codemirror_included
            content_for :header_tags do
              javascript_include_tag(:codemirror, :plugin => 'redmine_codemirror') +
              javascript_include_tag(:textile, :plugin => 'redmine_codemirror') +
              stylesheet_link_tag(:codemirror, :plugin => 'redmine_codemirror')
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
