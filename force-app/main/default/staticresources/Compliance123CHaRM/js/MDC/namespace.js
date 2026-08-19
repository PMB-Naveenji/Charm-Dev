
var mdc = {
	
	tables: {},
	fields: {},
	
	__construct : function() {

		function Utility() {
		}
		Utility.prototype = {};
		this.Utility = Utility;

		function UserTickets() {
		}
		UserTickets.prototype = {};
		this.UserTickets = UserTickets;

	
		this.sfdc = {
		
			tables: {},
			fields: {},
		
			__construct: function() {
			
				function Connection() {
				}
				Connection.prototype = {};
				this.Connection = Connection;
				
				function PublicGroupUtil() {
				}
				PublicGroupUtil.prototype = {};
				this.PublicGroupUtil = PublicGroupUtil;
				
				function Describe() {
				}
				Describe.prototype = {};
				this.Describe = Describe;
				
			}
		}
	}
};

mdc.__construct();
mdc.sfdc.__construct();
