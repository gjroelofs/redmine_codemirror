/* ***** BEGIN LICENSE BLOCK *****
 * This file is part of DotClear.
 * Copyright (c) 2005 Nicolas Martin & Olivier Meunier and contributors. All
 * rights reserved.
 *
 * DotClear is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * DotClear is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with DotClear; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * ***** END LICENSE BLOCK *****
*/

/* Modified by JP LANG for textile formatting */

function jsToolBar(textarea) {
	if (!document.createElement) { return; }
	
	if (!textarea) { return; }
	
	// if ((typeof(document["selection"]) == "undefined")
	// && (typeof(textarea["setSelectionRange"]) == "undefined")) {
	// 	return;
	// }
	
	this.textarea = textarea;

	//this.editor = document.createElement('div');
	//this.editor.className = 'jstEditor';
	
	//this.textarea.parentNode.insertBefore(this.editor,this.textarea);
	//this.editor.appendChild(this.textarea);
	
	this.toolbar = document.createElement("div");
	this.toolbar.className = 'jstElements';
	var target = this.textarea.getWrapperElement();
	target.parentNode.insertBefore(this.toolbar, target);
		
	this.context = null;
	this.toolNodes = {}; // lorsque la toolbar est dessinée , cet objet est garni 
							// de raccourcis vers les éléments DOM correspondants aux outils.
}

function jsButton(title, fn, scope, className) {
    if(typeof jsToolBar.strings == 'undefined') {
      this.title = title || null;
    } else {
      this.title = jsToolBar.strings[title] || title || null;
    }
	this.fn = fn || function(){};
	this.scope = scope || null;
	this.className = className || null;
}
jsButton.prototype.draw = function() {
	if (!this.scope) return null;
	
	var button = document.createElement('button');
	button.setAttribute('type','button');
	button.tabIndex = 200;
	if (this.className) button.className = this.className;
	button.title = this.title;
	var span = document.createElement('span');
	span.appendChild(document.createTextNode(this.title));
	button.appendChild(span);
	
	if (this.icon != undefined) {
		button.style.backgroundImage = 'url('+this.icon+')';
	}
	if (typeof(this.fn) == 'function') {
		var This = this;
		button.onclick = function() { try { This.fn.apply(This.scope, arguments) } catch (e) {} return false; };
	}
	return button;
}

function jsSpace(id) {
	this.id = id || null;
	this.width = null;
}
jsSpace.prototype.draw = function() {
	var span = document.createElement('span');
	if (this.id) span.id = this.id;
	span.appendChild(document.createTextNode(String.fromCharCode(160)));
	span.className = 'jstSpacer';
	if (this.width) span.style.marginRight = this.width+'px';
	
	return span;
} 

function jsCombo(title, options, scope, fn, className) {
	this.title = title || null;
	this.options = options || null;
	this.scope = scope || null;
	this.fn = fn || function(){};
	this.className = className || null;
}
jsCombo.prototype.draw = function() {
	if (!this.scope || !this.options) return null;

	var select = document.createElement('select');
	if (this.className) select.className = className;
	select.title = this.title;
	
	for (var o in this.options) {
		//var opt = this.options[o];
		var option = document.createElement('option');
		option.value = o;
		option.appendChild(document.createTextNode(this.options[o]));
		select.appendChild(option);
	}

	var This = this;
	select.onchange = function() {
		try { 
			This.fn.call(This.scope, this.value);
		} catch (e) { alert(e); }

		return false;
	}

	return select;
}


jsToolBar.prototype = {
	base_url: '',
	mode: 'wiki',
	elements: {},
	help_link: '',
	
	getMode: function() {
		return this.mode;
	},
	
	setMode: function(mode) {
		this.mode = mode || 'wiki';
	},
	
	switchMode: function(mode) {
		mode = mode || 'wiki';
		this.draw(mode);
	},
	
	setHelpLink: function(link) {
		this.help_link = link;
	},
	
	button: function(toolName) {
		var tool = this.elements[toolName];
		if (typeof tool.fn[this.mode] != 'function') return null;
		var b = new jsButton(tool.title, tool.fn[this.mode], this, 'jstb_'+toolName);
		if (tool.icon != undefined) b.icon = tool.icon;
		return b;
	},
	space: function(toolName) {
		var tool = new jsSpace(toolName)
		if (this.elements[toolName].width !== undefined)
			tool.width = this.elements[toolName].width;
		return tool;
	},
	combo: function(toolName) {
		var tool = this.elements[toolName];
		var length = tool[this.mode].list.length;

		if (typeof tool[this.mode].fn != 'function' || length == 0) {
			return null;
		} else {
			var options = {};
			for (var i=0; i < length; i++) {
				var opt = tool[this.mode].list[i];
				options[opt] = tool.options[opt];
			}
			return new jsCombo(tool.title, options, this, tool[this.mode].fn);
		}
	},
	draw: function(mode) {
		this.setMode(mode);
		
		// Empty toolbar
		while (this.toolbar.hasChildNodes()) {
			this.toolbar.removeChild(this.toolbar.firstChild)
		}
		this.toolNodes = {}; // vide les raccourcis DOM/**/

		// Draw toolbar elements
		var b, tool, newTool;
		
		for (var i in this.elements) {
			b = this.elements[i];

			var disabled =
			b.type == undefined || b.type == ''
			|| (b.disabled != undefined && b.disabled)
			|| (b.context != undefined && b.context != null && b.context != this.context);
			
			if (!disabled && typeof this[b.type] == 'function') {
				tool = this[b.type](i);
				if (tool) newTool = tool.draw();
				if (newTool) {
					this.toolNodes[i] = newTool; //mémorise l'accès DOM pour usage éventuel ultérieur
					this.toolbar.appendChild(newTool);
				}
			}
		}
	},
	
	singleTag: function(stag,etag) {
		stag = stag || null;
		etag = etag || stag;
		
		if (!stag || !etag) { return; }
		
		this.encloseSelection(stag,etag);
	},
	
	encloseLineSelection: function(prefix, suffix, fn) {
		this.textarea.focus();
		
		prefix = prefix || '';
		suffix = suffix || '';
		
		var start, end, sel, scrollPos, subst, sel;
		
		// TODO: Handle complete line selection
		//start = this.textarea.selectionStart;
		//	end = this.textarea.selectionEnd;
		//	scrollPos = this.textarea.scrollTop;
			// go to the start of the line
		//	start = this.textarea.value.substring(0, start).replace(/[^\r\n]*$/g,'').length;
			// go to the end of the line
        //  end = this.textarea.value.length - this.textarea.value.substring(end, this.textarea.value.length).replace(/^[^\r\n]*/, '').length;
			

		// Get the selection from CodeMirror
		sel = this.textarea.getSelection()
		
		if (sel.match(/ $/)) { // exclude ending space char, if any
			sel = sel.substring(0, sel.length - 1);
			suffix = suffix + " ";
		}
		
		if (typeof(fn) == 'function') {
			res = (sel) ? fn.call(this,sel) : fn('');
		} else {
			res = (sel) ? sel : '';
		}
		
		subst = prefix + res + suffix;
		
		// Call replace on CodeMirror
		this.textarea.replaceSelection(subst, "around")
	},
	
	encloseSelection: function(prefix, suffix, fn) {
		this.textarea.focus();
		
		prefix = prefix || '';
		suffix = suffix || '';
		
		var start, end, sel, scrollPos, subst, res;
		
		// Get the selection from CodeMirror
		sel = this.textarea.getSelection()
		
		if (sel.match(/ $/)) { // exclude ending space char, if any
			sel = sel.substring(0, sel.length - 1);
			suffix = suffix + " ";
		}
		
		if (typeof(fn) == 'function') {
			res = (sel) ? fn.call(this,sel) : fn('');
		} else {
			res = (sel) ? sel : '';
		}
		
		subst = prefix + res + suffix;
		
		// Call replace on CodeMirror
		this.textarea.replaceSelection(subst, "around")
	},
	
	stripBaseURL: function(url) {
		if (this.base_url != '') {
			var pos = url.indexOf(this.base_url);
			if (pos == 0) {
				url = url.substr(this.base_url.length);
			}
		}
		
		return url;
	}
};
