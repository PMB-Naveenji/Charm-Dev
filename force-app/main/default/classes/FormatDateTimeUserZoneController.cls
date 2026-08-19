/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : FormatDateTimeUserZoneController.
* @Why   : Class to Handle User Time Zone Format used on FormatDateTimeUserZone VF Component.
* @When  : 21-NOV-2017.
* @Where : From FormatDateTimeUserZoneController.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    21-NOV-2017            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    17-AUG-2020            Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class FormatDateTimeUserZoneController {

    public DateTime objDateTime { get; set; } //property that reads the datetime value from the component attribute tag
    public String strDefinedFormat { get; set; } //property that reads the string value from the component attribute tag

    /*
    * @Method       : getFormattedDatetime.
    * @Description  : Formats objDateTime basing on user's time zone and locale and strDefinedFormat.
    * @Invoke       : From CFormatDateTimeUserZone visualforce component.
    * @Return       : Formatted string with date/time.
    * @Params       : N/A.
    */
    public String getFormattedDatetime() {
        if(objDateTime == null){ //if no objDateTime value is provided
            return ''; //return blank string
        }else{ //otherwise, a objDateTime value was provided
            if (strDefinedFormat == null){ //if the format for the objDateTime value was not provided
                return objDateTime.format(); //return the full date/time for the user based upon the locale and time zone (the format() method provides the string in the running user's time zone and locale)
            } else { //otherwise, the format was provided
                return objDateTime.format(strDefinedFormat); //return the objDateTime value formatted as requested but with the locale and time zone taken into consideration
            }
        }
    }

}