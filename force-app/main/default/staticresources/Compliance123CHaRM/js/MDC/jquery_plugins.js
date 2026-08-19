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
		    		})
		    		.appendTo($("body"));
		    		
		    
		    	this.setTitle = function(title) {
		    		this.__titleBox.css({
		    			borderBottom: (!title || title.length === 0) ? "none" : "1px solid #999999"
		    		})
		    		.html(title);
		    		
		    		return this;
		    	};
		    
		    	var width = options ? (options.width | 300) : 300;
		    	var height = options ? (options.height | 200) : 200;
		    
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
		    		
		    		
		    	this.__buttonCell1 = $("<td></td>")
		    		.css({
		    			width: "100%"
		    	});
		    	this.__buttonCell2 = $("<td></td>");
		    	this.__buttonCell3 = $("<td></td>");
		    	this.__buttonCell4 = $("<td></td>");

		    	var okButton = $("<button></button>")
		    		.attr("id", "okButton")
	   				.css({
	   					padding: "7px",
	   					lineHeight: "11px",
	   					display: "none"
	   				})
	   				.attr("type", "button")
	   				.html("OK")
	   				.click(function(){
	   					__this.close();
	   				});
		    	
	   			this.__buttonCell3.append(okButton);	


		    	var cancelButton = $("<button></button>")
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
		    	
	   			this.__buttonCell4.append(cancelButton);	
		    	
		    	
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
		    		this.__overlay.hide();
		    		return this;
		    	};
		    	
		    	this.clear = function() {
		    		this.children(".uiType").hide();
		    		return this;
		    	};
		    	
		    	this.open = function() {
		    		this.__overlay.show();
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
		   			
		   			
					var buttons = options.buttons ? options.buttons : "none";
					this.__showButtons(buttons);
		   			this.open();
		   				
		    		return this;
		    	};
		    	
		    	this.textAreaInput = function(options) {
		    		this.close();
		    		this.clear();
		    		
		    		if (options.label) {
		    			this.__textAreaInputLabel.html(options.label);
		    		}

					var __this = this;		    		
		    		if (options.onOk) {
		    			$("#okButton", this.__buttonBar).one("click", function(){
		    				options.onOk(__this.__textAreaInput.val());
		    			});
		    		}
		    		
		    		this.__textAreaInputBox.show();
    		
		    		var buttons = options.buttons ? options.buttons : "ok";
		    		this.__showButtons(buttons);
		    		
		    		this.open();
		    	
		    		return this;
		    	};
		    	
		    
		    	return this;
		    };
		 
		}(jQuery));
