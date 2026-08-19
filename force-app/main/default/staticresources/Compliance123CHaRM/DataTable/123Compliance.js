
    
        var j = jQuery.noConflict();
        var stepid,value,commentreq=false;
        var isEsignPasswordReq = false;
        var userRec,owdSetting;
        var loginCount = 1;
        j(document).ready(function(){
            getWFSteps(); 
        });
            
        function getWFSteps(){            
            var workflow_detail = '<div id="wfdetails" style="margin-top:5px;"><div id="showSfdcError" align="center" style="color:#C00;display:none;"></div></div> ';  
            try{ 
                Visualforce.remoting.Manager.invokeAction(RAGetComplianceDet,recordId,function(result, event){ 
                    if(event.status){                       
                        result = htmlDecode(result);
                        var cmpldet = JSON.parse(result); 
                        recordId = cmpldet.recordId18;
                        isSamlAuth = cmpldet.isSamlAuth;
                        var historyLink = '<div class="row"><div style="float:right;margin-right:2%;"> <a href="#" style="text-decoration:none;" id="linkToAuditReport" target="_blank" ><img  src="/resource/MDC123__Compliance123/Image/AuditTrail.png" /></a>&nbsp;&nbsp;<a href="#" style="text-decoration:none;" id="linkToReport" target="_blank"><img height="21px;"  src="/resource/MDC123__Compliance123/Image/WorkflowHistory.png" /></a></div></div>';
                        j(workflow_detail).appendTo(isFromEMDRLayout == 'true'  ? j("#EMDRLayoutPannel") : 'body');
                        j(historyLink).appendTo("#wfdetails");                               
                        if((typeof sforce != 'undefined') && (sforce != null)){
                            j("#wfdetails").empty();
                            isPartialRefresh = false;
                            j("#signature_popup").remove();
                        }else{
                            j("#basicModal").remove();
                        }
                        userRec = cmpldet.userDetail;
                        owdSetting = cmpldet.owdSetting; 
                        j('#linkToReport').attr('href','/apex/MDC123__WorkflowHistory?id='+recordId); 
                        j('#linkToAuditReport').attr('href','/apex/MDC123__AuditTrail?id='+recordId);
                        cmpldet.isWorkflowEnabled != true ? j('#linkToReport').hide() : j('#linkToReport').show();       
                        cmpldet.isAuditEnabled != true ? j('#linkToAuditReport').hide() : j('#linkToAuditReport').show();  
                        if(cmpldet.isWorkflowEnabled){
                            var status=cmpldet.actionStatus != null ? cmpldet.actionStatus : '';  
                            var statusdet = '<div style="float:left;font-weight:bold;" >Current Status: '+status+'</div>'; 
                            var buttonHtml=''; 
                            if(cmpldet.wfsteps != null && cmpldet.wfsteps.length > 0){
                                response = cmpldet.wfsteps;
                                response.sort(function(a,b) { return parseFloat(a.MDC123__Order__c) - parseFloat(b.MDC123__Order__c) } ); 
                                for(i=0;i<response.length;i++){         
                                    var issignreq=response[i].MDC123__Action__r.MDC123__Is_ESign_Required__c;     
                                    var isCommentReq=response[i].MDC123__Action__r.MDC123__Is_Comment_Required__c;
                                    var action_message=response[i].MDC123__Action__r.MDC123__Esign_Message__c;
                                    var commentType = response[i].MDC123__Action__r.MDC123__Comment_Type__c;
                                    var dropdownOption = response[i].MDC123__Action__r.MDC123__Generic_Comment__c;
                                    dropdownOption = dropdownOption == null || dropdownOption == '' ? '' : dropdownOption;
                                    if(dropdownOption != '' && dropdownOption.indexOf(',\r\n') >-1){
                                        dropdownOption  = dropdownOption.replace(/[\r\n]/g, "");
                                    }else if(dropdownOption != '' && dropdownOption.indexOf('\r\n') >-1){
                                          dropdownOption  = dropdownOption.replace(/(\r\n|\n|\r)/gm,",");
                                    }
                                    if(dropdownOption != '' && dropdownOption.lastIndexOf(',')+1 == dropdownOption.length){
                                        dropdownOption = dropdownOption.substring(0,dropdownOption.lastIndexOf(','));
                                    }
                                    if((typeof sforce != 'undefined') && (sforce != null))
                                        buttonHtml += '<input type="button" id="'+response[i].Id+'" class="form-control btn btn-primary col-lg-6"  value="'+response[i].MDC123__Action__r.Name+'" class="actionbtns" style="margin-bottom:2px;" onclick="check(this.id,\''+dropdownOption+'\',\''+commentType+'\','+issignreq+',\''+action_message+'\','+isCommentReq+')" />';  
                                    else
                                        buttonHtml += '<button type="button"  class="btn btn-base" style="margin-top:5px;" id="'+response[i].Id+'"   onclick="check(this.id,\''+dropdownOption+'\',\''+commentType+'\','+issignreq+',\''+action_message+'\','+isCommentReq+')"><span style="letter-spacing: -0.1px;">'+response[i].MDC123__Action__r.Name+'</span></button>'; 
                                }
                            }      
                            if((typeof sforce != 'undefined') && (sforce != null)){
                                var dv = '<div class="navbar navbar-default" style="border-color:white;"><div class="navbar-header"><button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-inverse-collapse">';
                                dv += '<span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button><a class="navbar-brand" href="#" style="font-size:14px;">Current Status: <span style="color:#006EB3;font-size:13px;">'+cmpldet.actionStatus+'</span></a></div>';
                                dv += '<div class="navbar-collapse collapse navbar-inverse-collapse">';
                                dv +='<form class="navbar-form navbar-left" >'+buttonHtml;
                                dv +='</form></div>';
                                dv +='</div>';                                                                                      
                                j("#wfdetails").append(dv);
                            }else{
                                j("#wfdetails").append(' <div class="strip"><div>RECORD WORKFLOW</div></div><div class="well"><div class="container-fluid"></div><div class="container-fluid" ><div class="row" id="stataus_action_div"></div></div></div>');
                                j('<div class="col-md-4" style="text-align:left"><span style="color:rgb(95,95,95);font-weight:600">CURRENT STATUS:</span><br/><span style="font-weight:700;font-size:17px;color:#3498db">'+status+'</span></div>').appendTo("#stataus_action_div");  
                                j('<div class="col-md-8" style="text-align:right;margin-top:5px;">'+buttonHtml+'</div>').appendTo("#stataus_action_div");  
                            }  
                        }
                     }
                },{escape:true});
            }catch(e){
                alert(e);
            } 
        }        
        
        
        function htmlDecode(input){
            var e = document.createElement('div');
            e.innerHTML = input;
            return e.textContent;
        }     
        
        function check(stpid,dropdownOption,commentType,isEsign, val, commentRequired) {
            j(".textarea").remove();
            j('#password-attempt-history').hide();  
            var textArea,selectOption;
            var commentOption='<option value="">Select Comment</option>';
            if(commentType == 'Dropdown'){
               if(dropdownOption != null && dropdownOption != ''){
                    if(dropdownOption.indexOf(',') > -1){
                        for(var key=0;key< dropdownOption.split(',').length;key++){
                        commentOption += '<option  value="'+dropdownOption.split(',')[key]+'">'+dropdownOption.split(',')[key]+'</option>';
                    }
                    }else{
                        commentOption += '<option value="'+dropdownOption+'">'+dropdownOption+'</option>';
                    }
               }
            }
            if((typeof sforce != 'undefined') && (sforce != null)){
               textArea = '<textarea class="form-control textarea" id="commentArea" onfocus="j(this).next().hide();"></textarea><span id="commreq" class="commentdet textarea" style="color:red;padding-left:10px;display:none;">Comment is required </span>';
               selectOption = '<select onchange="j(this).next().hide();" class="form-control textarea" id="commentArea">'+commentOption+'</select><span id="commreq" class="commentdet textarea" style="color:red;padding-left:10px;display:none;">Comment is required </span>';
            }else{   
               textArea = '<input id="commentArea"  type="text" class="form-control textarea"  placeholder="Comment" style="width:340px"></input>';
               selectOption = '<select onchange="j(this).next().hide();" class="form-control textarea" id="commentArea">'+commentOption+'</select>';
            }  
               
            var commentSection = (commentType == 'Text' || commentType == 'undefined')? textArea : selectOption;
            j("#commentAreaDiv").append(commentSection);
            commentreq = commentRequired.toString();
            stepid = stpid;
            value = (val == 'undefined' ? '' : val);
            j('#commentArea').val('');
            j('#password').val('');
            isEsignPasswordReq = isEsign;
            if(isEsign) {           
                userLogin();
            }else if(!isEsign && commentreq == 'true'){
                openCommentPopup();     
            }else{
                updateActions('false');                       
            } 
        }
        
        function openCommentPopup(){
            j("#usernametd").hide();
            j("#password").hide();
            j("#pwdRequired").hide();
            userLogin();
        }
        
        function submitComment(){
            j('#popupErrorMsg').html('');   
            if(commentreq == 'true'){
                if(j('#commentArea').val() != null && j('#commentArea').val() !=''){
                    updateActions('true');                        
                }else{
                    if((typeof sforce != 'undefined') && (sforce != null)){
                        j("#commreq").show();
                    }else{
                        j('#popupErrorMsg').html('Comment is required');   
                    }
                }                    
            }
        }
        
        
        function userLogin(){
           if((typeof sforce != 'undefined') && (sforce != null)){ 
               j(".msg").html("");
               if(commentreq == 'true')
                   j('#showcomment').show();
               else
                   j('#showcomment').hide();
               j('#validationError').text('');
               j(".modal-header h4").html("E-signature for:"+value);
               j("#usernametd").val(userRec.Username);
               j('#basicModal').modal('show');
                   
           }else{
                if(!owdSetting.isSamlAuth){
                    j('#signature_popup').show(); 
                    if(commentreq == 'true')
                        j('#showcomment').show();
                    else
                        j('#showcomment').hide();
                    j('#signature_popup').dialog({ 
                        title: 'E-signature for: '+value,
                        height : isFromEMDRLayout == 'true' ? '120' : j("#wfdetails").height()-5,
                        width: j("#wfdetails").width()-20,
                        modal: true,
                        resizable: false,
                        closeOnEscape : false,
                        draggable : false,
                        position: ['center', 'middle']                  
                    });
                   window.addEventListener('keyup',bindEnterButton);
                }else{
                    var w = screen.width/2;
                    var h = screen.height/2;
                    var l = (screen.width/2)-(w/2);
                    var t = (screen.height/2)-(h/2);
                    var host = window.location.host;
                    host = host.replace('c.','MDC123.');
                    host = host.replace('cmpl123cme.','MDC123.');
                    var relayState = window.location.protocol+'//'+host+'/apex/MDC123__X123SAMLValidator?recordId='+recordId+'~stepId='+stepid;
                    var strWindowFeatures = "top="+t+",left="+l+",width="+w+",height="+h+",menubar=no,location=no,resizable=yes,scrollbars=no,status=no";
                    var url = owdSetting.idpLogoutUrl+'?TARGET='+owdSetting.baseUrl+'/apex/MDC123__X123SAMLInit?RelayState='+relayState;
                    var samlwin = window.open(url,'SAML',strWindowFeatures);
                    var timer = setInterval(function() {   
                        if(samlwin.closed) {  
                            clearInterval(timer);  
                            redirect();
                        }  
                    }, 1000);            
                }       
            }   
        }
        
        function validatePwd(){ 
            if(isEsignPasswordReq){
                var password = j('#password').val();
                if(password  != null && j.trim(password).length > 0){
                    var iscommentreq=true;  
                    j('#popupErrorMsg').html('');   
                    if(commentreq == 'true'){
                        if(j('#commentArea').val() != null && j('#commentArea').val() !=''){
                            iscommentreq = false;                        
                        }else{
                            iscommentreq = true;  
                            if((typeof sforce != 'undefined') && (sforce != null)){
                                 j("#commreq").show();
                            }else{
                                j('#popupErrorMsg').html('Comment is required');   
                            }
                        }                    
                    }else
                        iscommentreq = false;             
                   
                    if(!iscommentreq){
                        freezeBtn();                     
                        if(isEsignPwdReq  == 'true'){   
                            Visualforce.remoting.Manager.invokeAction(RAEsignValidate,j('#usernametd').val(),password, function(result, event){
                                if(event.status){
                                    isvalid = result;
                                }else{
                                    isvalid = false;
                                }
                                if(isvalid == false){ 
                                    unFreezeBtn();                                
                                    if(loginCount < 3){    
                                        loginCount++;     
                                        if((typeof sforce != 'undefined') && (sforce != null)){
                                            j('#nooftimes').html((4-loginCount) == 2 ? 'Two more tries' : 'One more try');
                                            j('#password-attempt-history').show();  
                                        }else{
                                            j('#popupErrorMsg').html(((4-loginCount) == 2 ? 'Two more tries' : 'One more try')+' left before you will be logged out of the system');
                                        } 
                                    }else{  
                                        logout();
                                    }    
                                }else{       
                                    updateActions('true');                      
                                }   
                            }, {escape:true}); 
                        }else{
                            if(password == userRec.MDC123__ESign_Password__c ){
                                updateActions('true'); 
                            }else{
                                unFreezeBtn();     
                                if(loginCount < 3){    
                                    loginCount++;     
                                    if((typeof sforce != 'undefined') && (sforce != null)){
                                        j('#nooftimes').html((4-loginCount) == 2 ? 'Two more tries' : 'One more try');
                                        j('#password-attempt-history').show();  
                                    }else{
                                        j('#popupErrorMsg').html(((4-loginCount) == 2 ? 'Two more tries' : 'One more try')+' left before you will be logged out of the system');
                                    } 
                                }else{  
                                    logout();
                                }  
                            }
                        }                 
                    }       
                }else{   
                    if((typeof sforce != 'undefined') && (sforce != null)){
                        j("[id$=password]").next().html('E-sign password is required');     
                    }else{    
                        j('#popupErrorMsg').html('E-sign password is required'); 
                    }                            
                }
            }else if(commentreq == 'true'){
                submitComment();
            }    
        }  
        
        
        
        function updateActions(isEsignReq){
            Visualforce.remoting.Manager.invokeAction(RAEsignSubmit,recordId,stepid,j("#commentArea").val(), function(result, event){
                unFreezeBtn();
                if(event.status){                       
                    if(result == null || result == ''){                              
                        redirect();
                    }else{
                        if(isFromEMDRLayout == 'false'){
                            if(isEsignReq == 'false'){
                                j('#showSfdcError').text(result);
                                j('#showSfdcError').show();
                            
                            }else{
                                j('#popupErrorMsg').html(result);
                                j('#validationError').text(result);
                                j('#validationError').show();
                                j('#password-attempt-history').hide(); 
                            }   
                        }else{
                             eval('showEMDRWorkflowPanel("'+result+'")');
                             j('#signature_popup').dialog( "close" );
                        } 
                    }  
                }
            },{escape:true});
        }  
        
        function redirect(){
            if((typeof sforce != 'undefined') && (sforce != null))
                sforce.one.navigateToSObject(recordId,'detail');
            else{    
                if(isPartialRefresh == 'false'){                    
                    if(isInConsole() == true){ 
                        obj.console.getEnclosingPrimaryTabId(refreshTab);
                    }else                   
                        parent.location.href = "/"+recordId;
                }else{
                    closeEsignPopup();
                    j("#wfdetails").empty();
                    getWFSteps();
                }
            }    
        }
        
        var refreshTab = function reloadTab(result) {
            var tabId = result.id;
            obj.console.refreshPrimaryTabById(tabId);
        }; 
        
        function logout(){   
            if(((typeof sforce != 'undefined') && (sforce != null))){               
                sforce.one.navigateToURL('/home/home.jsp');
            }else if(isInConsole() == true)
                parent.top.location.href = '/secur/logout.jsp'; 
            else
                parent.location.href='/secur/logout.jsp';               
        }
        
        function closeEsignPopup(){
            loginCount = 1;
             window.removeEventListener('keyup',bindEnterButton);
           
            if((typeof sforce != 'undefined') && (sforce != null))
                j('.msg').html('');
            else{    
                j('#signature_popup').dialog('close'); 
                j('#popupErrorMsg').html(''); 
            }
        }
        
        function freezeBtn(){
            var jbtn1 = j("#validatePassword");
            var jbtn2 = j("#refreshPage");            
            jbtn1.button('loading');   
            jbtn2.button('loading');
        }
        
        function unFreezeBtn(){            
            var jbtn1 = j("#validatePassword");
            var jbtn2 = j("#refreshPage");            
            jbtn1.button('reset');   
            jbtn2.button('reset');
        }
        
        function isInConsole(){
            var qs = location.search;
            return !(typeof sforce != "undefined" && sforce.one) && (qs.length !== 0 && ((qs.indexOf("?isdtp=") > -1) || (qs.indexOf("&isdtp=") > -1)));
        }
        
        function bindEnterButton(e){
            
            if(e.keyCode == 13)
                 validatePwd();
        }