
// Defines two jQuery plugins:
//
//    _123Popup
//    expandCollapseBox
//
//    _123Popup is a popup window which can be initialized with 
//    with three different kinds of content
//        - waiter
//        - message box
//        - text area input
//
//
//    waiter pops up a box with a spinner and customizable
//    message. example call:
//
//
//		$("<div></div>")._123Popup()
//			.setTitle("MDC Ticket Dashboard")
//			.waiter({
//				waitText: "Loading <br />Please wait..."
//			});
//		OR
//
//		$("<div></div>")._123Popup({
//			title: "MDC Ticket Dashboard"	
//		})
//		.waiter({
//			waitText: "Loading <br />Please wait..."
//		});
//
//
//
//		message box sample call:
//
//		$("<div></div>")._123Popup({
//			title: "Acknowledgments",
//			buttons: "ok",
//			width: 300,
//			height: 120,
//			onOk: function() {
//				... code here	
//			}
//		})
//		.message({
//			messageText: "Please select tickets to acknowledge."
//		});
//
//		buttons: can be "ok" or "okCancel"
//      okButtonLabel: supply alternate label for OK button
//		cancelButonLabel: supply alternate label for Cancel button
//		onOK: handler for OK button press
//		onOpen: handler for when popup is opened
//		onClose: handler for when popup is closed
//
//
//
//
//
//		text area input sample call:
//
//		$("<div></div>")._123Popup({
//			title: "Acknowledge With Comments",
//			buttons: "okCancel",
//			okButtonLabel: "Acknowledge",
//			onOk: function(commentText, popup) {
//			
//				if (commentText.trim().length === 0) {
//					popup.setError("Please enter a comment.");
//					return false;
//				}
//				
//				... call success method here
//				return true;
//			}
//		})
//	   .textAreaInput({
//			intro: "Please enter your comment and click Acknowledge",
//			maxLength: 500
//		}); 



(function ($) {
 
	$.fn._123Popup = function(options) {
	
		this.__overlay = $("<div></div>")
			.css({
				display: "none",
				position: "fixed",
				top: "0px",
				left: "0px",
				width: "100%",
				height: "100%",
				backgroundColor: "rgba(255,255,255, 0.5)",
				zIndex: "1000"
			});
			

		this.setButtons = function(buttons) {
			this.__showButtons(buttons);
			return this;
		};
		
		this.setTitle = function(title) {
			this.__titleBox.css({
				borderBottom: (!title || title.length === 0) ? "none" : "1px solid #999999"
			})
			.html(title);
			
			return this;
		};

		this.setOkButtonLabel = function(label) {
			this.__okButton.html(label);
			return this;
		};

		this.setCancelButtonLabel = function(label) {
			this.__cancelButton.html(label);
			return this;
		};
		
		this.setOnOk = function(onOk) {		
			var __this = this;		    		
			$("#okButton", this.__buttonBar).click(function(){
				if (onOk(__this.__textAreaInput.val(), __this)) {
					__this.close();
				}
			});
			return this;
		}
		
		
		this.setError = function(error) {
			$(".errorBox", this).text(error)
		}
		
		var width = (options && options.width) ? options.width : 300;
		var height = (options && options.height) ? options.height : 200; 
	
		this.css({
			width: width + "px",
			height: height + "px",
			border: "1px solid black",
			position: "fixed",
			
			top: "50%",
			left: "50%",
			marginTop: "-" + (height / 2) + "px",
			marginLeft: "-" + (width / 2) + "px",
			
			backgroundColor: "white",
			padding: "20px",
			zIndex: "2000"
		})
		.appendTo(this.__overlay);
		
		this.__titleBox = $("<div></div>")
			.css({
				borderBottom: "1px solid #666666",
				textAlign: "center",
				paddingBottom: "10px",
				fontWeight: "bold"
			});
		
		this.append(this.__titleBox);
		
		var __this = this;
		
		
		
		this.__waiter = $("<div></div>")
			.addClass("uiType")
			.css({
				display: "none",
				width: "100%",
				heigth: "100%"
			});
		
		
		this.__waitSpinner = $("<div></div>")
			.addClass("loader")
			.css({
				//display: "none",
				margin: "auto",
				marginTop: "30px"
			})
			.appendTo(this.__waiter);
			
		this.__waitText = $("<div></div>")
			.css({
				margin: "30px",
				textAlign: "center",
				color: "#444444",
				//display: "none"
			})
			.appendTo(this.__waiter);
			
		this.__messageBox = $("<div></div>")
			.addClass("uiType")
			.css({
				margin: "10px 18px",
				color: "#444444",
				maxHeight: (height - 94) + "px",
				overflowY: "auto",
				paddingRight: "10px",
				display: "none"
			});
			
		
		this.__textAreaInputBox = $("<div></div>")
			.addClass("uiType")
			.css({
				display: "none",
				width: "100%",
				height: "100%"
			});	
			
		this.__textAreaInputLabel = $("<div></div>")
			.css({
				margin: "10px",
				color: "#444444"
			})
			.appendTo(this.__textAreaInputBox);
			
		this.__textAreaInput = $("<textarea></textarea>")
			.attr("rows", "5")		    		
			.css({
				resize: "none",
				border: "1px solid lightgray",
				margin: "0px 10px",
				overflowY: "auto",
				overflowX: "hidden",
				width: (width - 25) + "px"
			})
			.appendTo(this.__textAreaInputBox);
			
			
			
			
		this.__textAreaInputErrorBox = $("<div></div>")
			.addClass("errorBox")
			.css({
				margin: "10px",
				color: "red"
			})
			.appendTo(this.__textAreaInputBox);
			
			
			
			
		this.__buttonCell1 = $("<td></td>")
			.css({
				width: "100%"
		});
		this.__buttonCell2 = $("<td></td>");
		this.__buttonCell3 = $("<td></td>");
		this.__buttonCell4 = $("<td></td>");

		this.__okButton = $("<button></button>")
			.attr("id", "okButton")
			.css({
				padding: "7px",
				lineHeight: "11px",
				display: "none"
			})
			.attr("type", "button")
			.html("OK");
		
		this.__buttonCell3.append(this.__okButton);	


		this.__cancelButton = $("<button></button>")
			.attr("id", "cancelButton")
			.css({
				padding: "7px",
				lineHeight: "11px",
				display: "none"
			})
			.attr("type", "button")
			.html("Cancel")
			.click(function(){
				__this.close();
			});
		
		this.__buttonCell4.append(this.__cancelButton);	
		
		
		this.__buttonBarTable = $("<table></table>")
			.css({
				borderCollapse: "collapse",
				borderSpacing: "0px"
			})
			.append($("<tr></tr>")
				.append(this.__buttonCell1)
				.append(this.__buttonCell2)
				.append(this.__buttonCell3)
				.append(this.__buttonCell4));
				
		
		this.__buttonBar = $("<div></div>")
			.css({
				height: "20px",
				position: "absolute",
				left: "0px",
				right: "0px",
				bottom: "0px",
				margin: "20px 30px 40px 30px"
			})
			.append(this.__buttonBarTable);
			
		this.append(this.__waiter, this.__messageBox, this.__textAreaInputBox, this.__buttonBar);
		
		
		if (options && options.title) {
			this.setTitle(options.title);
		}

		this.close = function() {
			this.__overlay
				.hide()
				.detach();
			
			if (options && options.onClose) {
				options.onClose();
			}
			return this;
		};
		
		this.clear = function() {
			this.children(".uiType").hide();
			return this;
		};
		
		this.open = function() {
			this.__overlay
				.appendTo($("body"))
				.show();

			if (options && options.onOpen) {
				options.onOpen();
			}				
			return this;
		};
	
		this.waiter = function(options) {
			this.close();
			this.clear();
			this.__waitText.html((options && options.waitText) ? options.waitText : "Please wait...");
			this.__waiter.show();
			this.open();
			return this;
		};
	
	
		this.__showButtons = function(buttons) {
			this.close();
			this.__buttonBar.hide();
			$("#okButton", this.__buttonBar).hide();
			$("#cancelButton", this.__buttonBar).hide();
			
			switch(buttons) {
				case "none":
					break;
				case "ok":
					$("#okButton", this.__buttonBar).show();
					break;
				case "cancel":
					$("#cancelButton", this.__buttonBar).show();
					break;
				case "okCancel":
					$("#okButton", this.__buttonBar).show();
					$("#cancelButton", this.__buttonBar).show();
					break;
			}
			
			this.__buttonBar.show();
		};
	
		this.message = function(options) {
			this.close();
			this.clear();
			

			if (options && options.size) {
				this.css({
					width: options.size.width + "px",
					height: options.size.height + "px"
				});
			}
			
			
			this.__messageBox.show();		
			this.__messageBox.html((options && options.messageText) ? options.messageText : "");
			
			
			this.open();
				
			return this;
		};
		
		this.textAreaInput = function(options) {
			this.close();
			this.clear();
			
			this.css({height: "220px"})
			
			if (options && options.maxLength) {
				this.__textAreaInput.attr("maxlength", options.maxLength + "")
			}
			
			if (options && options.intro) {
				this.__textAreaInputLabel.html(options.intro);
			}

			this.__textAreaInputBox.show();
	
			this.open();
		
			return this;
		};
		
		

		if (options && options.title) {
			this.setTitle(options.title);
		}

		var buttons = (options && options.buttons) ? options.buttons : "none";
		this.__showButtons(buttons);
	
		if (options && options.okButtonLabel) {
			this.setOkButtonLabel(options.okButtonLabel);
		}
		
		if (options && options.cancelButtonLabel) {
			this.setCancelButtonLabel(options.cancelButtonLabel);
		}
		
		
		
		if (options && options.onOk) {
			this.setOnOk(options.onOk)
		}
		else {
			this.__okButton.click(function() {
				__this.close();
			});
		}
		
	
		return this;
	};
	
	//
	//	 a div that contains arrow images and toggles expand / collapse of related
	//   content when clicked. Example call:
	//
	//	$("<div></div>").expandCollapseBox({
	//		openExpanded: true,
	//		collapseImageSrc: "{!URLFOR($Resource.Compliance123, '/Image/chevronleft_120.png')}",
	//		expandImageSrc: "{!URLFOR($Resource.Compliance123, '/Image/chevrondown_120.png')}",
	//		relatedContent: affectedFieldsHistoryTable
	//	}))
	//
	
	
	$.fn.expandCollapseBox = function(options) {
		
		if (!options.collapseImageSrc || !options.expandImageSrc) {
			return this;
		}
		
		this.__relatedContent = options.relatedContent;

		var defaultWidth = 18;
		var defaultHeight = 18;
		
		this.css({
			width: options.width || defaultWidth + "px",
			height: options.height || defaultHeight + "px",
			margin: "auto"
		})
		
		var __this = this;
		
		this.__state = false;
		this.__collapsedImage = $("<img />")
			.css({
				width: options.width || defaultWidth + "px",
				height: options.height || defaultHeight + "px"
			})
			.attr("src", options.collapseImageSrc);
			
		this.__expandedImage = $("<img />")
			.css({
				width: options.width || defaultWidth + "px",
				height: options.height || defaultHeight + "px",
				display: "none"
			})
			.attr("src", options.expandImageSrc); 		 
		
		this.css({
				cursor: "pointer"
			})
			.append(this.__collapsedImage)
			.append(this.__expandedImage)
			.click(function(){
				__this.__toggleState();
				
				if (__this.__state) {
					
					if (__this.__relatedContent) {
						__this.__relatedContent.show();
					}
					
					if (options.onExpand){
						options.onExpand();
					}
				}
				else {
					if (__this.__relatedContent) {
						__this.__relatedContent.hide();
					}
					
					if (options.onCollapse){
						options.onCollapse();
					}
				}
			});
			
		this.__toggleState = function() {
		
			this.__state = !this.__state;
			
			if (this.__state) {
				this.__collapsedImage.hide();
				this.__expandedImage.show();
			}
			else {
				this.__collapsedImage.show();
				this.__expandedImage.hide();
			} 
		};


		if (options && typeof(options.openExpanded) !== "undefined") {
			if (options.openExpanded) {
				this.__toggleState();
			}
		}

		this.setRelatedContent = function(relatedContent) {
			this.__relatedContent = relatedContent;
		};
		
		return this;
	};	
	
 
}(jQuery));
