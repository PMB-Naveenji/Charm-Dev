/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : SendAttachmentToTIBCOService.
* @Why   : To send attachment to TIBCO.
* @When  : 22-FEB-2019.
* @Where : From 'SendAttachmentToTIBCOBatch' class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    22-FEB-2019            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                    Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                    Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    09-JUL-2020            Code Audit                    Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class SendAttachmentToTIBCOService {
    /*
    * @Method       : sendAttachment.
    * @Description  : To send attachment to TIBCO.
    * @Invoke       : From 'SendAttachmentToTIBCOBatch' class.
    * @Return       : Error_Log__c.
    * @Params       : Attachment__c attachment.
    */
    public static Error_Log__c sendAttachment(Attachment__c attachment){
        String payLoad = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:out="http://soap.sforce.com/2005/09/outbound" xmlns:urn="urn:sobject.enterprise.soap.sforce.com"><soapenv:Header/><soapenv:Body><out:notifications><out:OrganizationId>';
        payLoad += UserInfo.getOrganizationId()+'</out:OrganizationId><out:ActionId>04k0j000000Cb57AAC</out:ActionId>';
        payLoad += '<out:SessionId>'+UserInfo.getSessionId()+'</out:SessionId><out:EnterpriseUrl>'+System.URL.getSalesforceBaseUrl().toExternalForm()+ '/services/Soap/c/44.0/'+ UserInfo.getOrganizationId()+'</out:EnterpriseUrl>';
        payLoad += '<out:PartnerUrl>'+System.URL.getSalesforceBaseUrl().toExternalForm()+ '/services/Soap/u/44.0/'+ UserInfo.getOrganizationId()+'</out:PartnerUrl><out:Notification><out:Id>04l0j000003v59nAAA</out:Id>';
        payLoad += '<out:sObject><urn:fieldsToNull>?</urn:fieldsToNull><urn:Id>'+attachment.Id+'</urn:Id><urn:File_Name__c>'+attachment.File_Name__c+'</urn:File_Name__c></out:sObject></out:Notification></out:notifications></soapenv:Body></soapenv:Envelope>';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(System.Label.TIBCO_EndPoint_URL);
        req.setMethod('POST');
        req.setBody(payLoad);

        Error_Log__c errorLog;
        String ticketNumber = attachment.CMSNext_Ticket_Number__c != null ? attachment.CMSNext_Ticket_Number__c : 'Ticket # not mentioned';

        try{
            HttpResponse res = h.send(req);
            Integer responseStatusCode = res.getStatusCode();
            if (responseStatusCode < 200 && responseStatusCode >= 300) {
                String errText = 'Received ' + responseStatusCode + ' (' + res.getStatus() + '): ';
                if (responseStatusCode < 200) {
                    errText += 'Informational error.';
                } else if (responseStatusCode >= 300 && responseStatusCode < 400) {
                    errText += 'Redirection error.';
                } else if (responseStatusCode >= 400 && responseStatusCode < 500) {
                    errText += 'Client error.';
                } else {
                    errText += 'Server error.';
                }
                errText += SendAttachmentToTIBCOService.resolveStatusCodeToText(responseStatusCode);
                errorLog = ErrorLogFormatter.GetFormattedError(ticketNumber, 'TIBCO Attachment Service Call Failed', errText, payLoad);
            }
        }catch(Exception ex){
            System.debug('==Exception in sending attachment to TIBCO'+ex);
            errorLog = ErrorLogFormatter.GetFormattedError(ticketNumber, 'TIBCO Attachment Service Call Failed', ex.getMessage(), payLoad);
        }

        return errorLog;
    }

    /*
    * @Method       : resolveStatusCodeToText.
    * @Description  : To map user-friendly error message with status code.
    * @Invoke       : From 'sendAttachment()' method.
    * @Return       : String.
    * @Params       : Integer statusCode.
    */
    @TestVisible
    private static String resolveStatusCodeToText(Integer statusCode) {
        String resolvedStatus = '';
        switch on statusCode {
            when 300 {
                resolvedStatus += ' The value returned when an external ID exists in more than one record.';
            }
            when 304 {
                resolvedStatus += ' The request content has not changed since a specified date and time. The date and time is provided in a If-Modified-Since header.';
            }
            when 400 {
                resolvedStatus += ' The request couldn’t be understood, usually because the JSON or XML body contains an error.';
            }
            when 401 {
                resolvedStatus += ' The session ID or OAuth token used has expired or is invalid.';
            }
            when 403 {
                resolvedStatus += ' The request has been refused. Verify that the logged-in user has appropriate permissions. If the error code is REQUEST_LIMIT_EXCEEDED, you’ve exceeded API request limits in your org.';
            }
            when 404 {
                resolvedStatus += ' The requested resource couldn’t be found. Check the URI for errors, and verify that there are no sharing issues.';
            }
            when 405 {
                resolvedStatus += ' The method specified in the Request-Line isn’t allowed for the resource specified in the URI.';
            }
            when 415 {
                resolvedStatus += ' The entity in the request is in a format that’s not supported by the specified method.';
            }
            when 500 {
                resolvedStatus += ' An error has occurred within Lightning Platform, so the request couldn’t be completed. Contact Salesforce Customer Support.';
            }
        }
        return resolvedStatus;
    }
}