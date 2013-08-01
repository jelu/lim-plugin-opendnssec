(function ($) {
	$(function () {
		window.lim.module.opendnssec = {
			init: function () {
				var that = this;
				
				$('.sidebar-nav a[href="#about"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadAbout();
	    			return false;
				});
				
				$('.sidebar-nav a[href="#"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
	    			return false;
				});
				
				this.loadAbout();
			},
			//
			loadAbout: function () {
				window.lim.loadPage('/_opendnssec/about.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
				});
			},
		};
		window.lim.module.opendnssec.init();
	});
})(window.jQuery);
