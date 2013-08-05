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
				$('.sidebar-nav a[href="#system-information"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadSystemInformation();
	    			return false;
				});
				
				// CONFIG

				$('.sidebar-nav a[href="#config_list"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadConfigList();
	    			return false;
				});
				$('.sidebar-nav a[href="#config_read"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadConfigRead();
	    			return false;
				});

				// CONTROL
				
				$('.sidebar-nav a[href="#control_start"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadControlStart();
					return false;
				});
				$('.sidebar-nav a[href="#control_stop"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadControlStop();
					return false;
				});
				
				// ENFORCER
				
				$('.sidebar-nav a[href="#enforcer_repository_list"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadEnforcerRepositoryList();
					return false;
				});
				$('.sidebar-nav a[href="#enforcer_zone_list"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadEnforcerZoneList();
					return false;
				});
				$('.sidebar-nav a[href="#enforcer_policy_list"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadEnforcerPolicyList();
					return false;
				});
				$('.sidebar-nav a[href="#enforcer_policy_export"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadEnforcerPolicyExport();
					return false;
				});
				$('.sidebar-nav a[href="#enforcer_key_list"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadEnforcerKeyList();
					return false;
				});
				$('.sidebar-nav a[href="#enforcer_backup_list"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadEnforcerBackupList();
					return false;
				});
				$('.sidebar-nav a[href="#enforcer_rollover_list"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadEnforcerRolloverList();
					return false;
				});
				$('.sidebar-nav a[href="#enforcer_update"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadEnforcerUpdate();
					return false;
				});
				
				// SIGNER
				
				$('.sidebar-nav a[href="#signer_zones"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadSignerZones();
					return false;
				});
				$('.sidebar-nav a[href="#signer_sign"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadSignerSign();
					return false;
				});
				$('.sidebar-nav a[href="#signer_clear"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadSignerClear();
					return false;
				});
				$('.sidebar-nav a[href="#signer_queue"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadSignerQueue();
					return false;
				});
				$('.sidebar-nav a[href="#signer_flush"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadSignerFlush();
					return false;
				});
				$('.sidebar-nav a[href="#signer_update"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadSignerUpdate();
					return false;
				});
				
				// HSM
				
				$('.sidebar-nav a[href="#hsm_info"]').click(function () {
					$('.sidebar-nav li').removeClass('active');
					$(this).parent().addClass('active');
					that.loadHsmInfo();
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
			//
			loadSystemInformation: function () {
				var that = this;

				window.lim.loadPage('/_opendnssec/system_information.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getSystemInformation();
				});
			},
			getSystemInformation: function () {
				window.lim.getJSON('/opendnssec/version')
				.done(function (data) {
					if (data.version) {
						$('#opendnssec-version').text(data.version);
					}
					else {
						$('#opendnssec-version i').text('failed');
					}
					
		    		if (data.program && data.program.length) {
		    			$('#opendnssec-content table tbody').empty();

			    		data.program.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.program, function () {
			    			$('#opendnssec-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.version)
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.program && data.program.name) {
		    			$('#opendnssec-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.program.name),
		    					$('<td></td>').text(data.program.version)
	    					));
			    		return;
		    		}
		    		
		    		$('#opendnssec-content table td i').text('No modules found, this is a bit strange ...');
				})
				.fail(function () {
					$('#opendnssec-version i').text('failed');
					$('#opendnssec-content table td i').text('failed');
				});
			},
			//
			// CONFIG
			//
			loadConfigList: function () {
				var that = this;
				
				window.lim.loadPage('/_opendnssec/config_list.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getConfigList();
				});
			},
			getConfigList: function () {
				window.lim.getJSON('/opendnssec/configs')
				.done(function (data) {
		    		if (data.file && data.file.length) {
		    			$('#opendnssec-content table tbody').empty();
		    			
			    		data.file.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.file, function () {
			    			$('#opendnssec-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.read ? 'Yes' : 'No'),
			    					$('<td></td>').text(this.write ? 'Yes' : 'No')
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.file && data.file.name) {
		    			$('#opendnssec-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.file.name),
		    					$('<td></td>').text(data.file.read ? 'Yes' : 'No'),
		    					$('<td></td>').text(data.file.write ? 'Yes' : 'No')
	    					));
		    			return;
		    		}
		    		
		    		$('#opendnssec-content table td i').text('No config files found');
				})
				.fail(function (jqXHR) {
					$('#opendnssec-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read config file list: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			loadConfigRead: function () {
				var that = this;
				
				window.lim.loadPage('/_opendnssec/config_read.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
		    		$('#opendnssec-content select').prop('disabled',true);
		    		$('#opendnssec-content .selectpicker').selectpicker();
		    		$('#opendnssec-content form').submit(function () {
	    				var file = $('#opendnssec-content select option:selected').text();
		    			if (file) {
		    				$('#opendnssec-content form').remove();
		    				$('#opendnssec-content').append(
		    					$('<p></p>').append(
		    						$('<i></i>')
		    						.text('Loading zone file '+file+' ...')
	    						));
		    				window.lim.getJSON('/opendnssec/config', {
		    					file: {
		    						name: file
		    					}
		    				})
		    				.done(function (data) {
		    					if (data.file && !data.file.length && data.file.name) {
		    						$('#opendnssec-content p').text('Content of the config file '+file);
		    						$('#opendnssec-content').append(
		    							$('<pre class="prettyprint linenums"></pre>')
		    							.text(data.file.content)
		    							);
		    						prettyPrint();
		    						return;
		    					}
		    					
								$('#opendnssec-content p')
								.text('Config file '+file+' not found');
		    				})
							.fail(function (jqXHR) {
								$('#opendnssec-content p')
								.text('Unable to read config file '+file+': '+window.lim.getXHRError(jqXHR))
								.addClass('text-error');
							});
		    			}
		    			return false;
		    		});
		    		$('#opendnssec-content #submit').prop('disabled',true);
		    		that.getConfigRead();
				});
			},
			getConfigRead: function () {
				window.lim.getJSON('/opendnssec/configs')
				.done(function (data) {
		    		if (data.file && data.file.length) {
		    			$('#opendnssec-content select').empty();
		    			
			    		data.file.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.file, function () {
			    			$('#opendnssec-content select').append(
			    				$('<option></option>').text(this.name)
			    				);
			    		});
			    		$('#opendnssec-content select').prop('disabled',false);
			    		$('#opendnssec-content .selectpicker').selectpicker('refresh');
			    		$('#opendnssec-content #submit').prop('disabled',false);
			    		return;
		    		}
		    		else if (data.file && data.file.name) {
		    			$('#opendnssec-content select')
		    			.empty()
		    			.append($('<option></option>').text(data.file.name));

			    		$('#opendnssec-content select').prop('disabled',false);
			    		$('#opendnssec-content .selectpicker').selectpicker('refresh');
			    		$('#opendnssec-content #submit').prop('disabled',false);
		    			return;
		    		}
		    		
		    		$('#opendnssec-content option').text('No config files found');
		    		$('#opendnssec-content .selectpicker').selectpicker('refresh');
				})
				.fail(function (jqXHR) {
					$('#opendnssec-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read config file list: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			// CONTROL
			//
			loadControlStart: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/control_start.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getControlStart();
				});
			},
			getControlStart: function () {
			},
			//
			loadControlStop: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/control_stop.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getControlStop();
				});
			},
			getControlStop: function () {
			},
			//
			// ENFORCER
			//
			loadEnforcerRepositoryList: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/enforcer_repository_list.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getEnforcerRepositoryList();
				});
			},
			getEnforcerRepositoryList: function () {
				window.lim.getJSON('/opendnssec/enforcer_repository_list')
				.done(function (data) {
		    		if (data.repository && data.repository.length) {
		    			$('#opendnssec-content table tbody').empty();
		    			
			    		data.repository.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.repository, function () {
			    			$('#opendnssec-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.capacity),
			    					$('<td></td>').text(this.require_backup ? 'Yes' : 'No')
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.repository && data.repository.name) {
		    			$('#opendnssec-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.repository.name),
		    					$('<td></td>').text(data.repository.capacity),
		    					$('<td></td>').text(data.repository.require_backup ? 'Yes' : 'No')
	    					));
		    			return;
		    		}
		    		
		    		$('#opendnssec-content table td i').text('No repositories found');
				})
				.fail(function (jqXHR) {
					$('#opendnssec-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read repository list: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			loadEnforcerZoneList: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/enforcer_zone_list.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getEnforcerZoneList();
				});
			},
			getEnforcerZoneList: function () {
				window.lim.getJSON('/opendnssec/enforcer_zone_list')
				.done(function (data) {
		    		if (data.zone && data.zone.length) {
		    			$('#opendnssec-content table tbody').empty();
		    			
			    		data.zone.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.zone, function () {
			    			$('#opendnssec-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.policy)
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.zone && data.zone.name) {
		    			$('#opendnssec-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.zone.name),
		    					$('<td></td>').text(data.zone.policy)
	    					));
		    			return;
		    		}
		    		
		    		$('#opendnssec-content table td i').text('No zones found');
				})
				.fail(function (jqXHR) {
					$('#opendnssec-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read zone list: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			loadEnforcerPolicyList: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/enforcer_policy_list.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getEnforcerPolicyList();
				});
			},
			getEnforcerPolicyList: function () {
				window.lim.getJSON('/opendnssec/enforcer_policy_list')
				.done(function (data) {
		    		if (data.policy && data.policy.length) {
		    			$('#opendnssec-content table tbody').empty();
		    			
			    		data.policy.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.policy, function () {
			    			$('#opendnssec-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.description)
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.policy && data.policy.name) {
		    			$('#opendnssec-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.policy.name),
		    					$('<td></td>').text(data.policy.description)
	    					));
		    			return;
		    		}
		    		
		    		$('#opendnssec-content table td i').text('No policies found');
				})
				.fail(function (jqXHR) {
					$('#opendnssec-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read policy list: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			loadEnforcerPolicyExport: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/enforcer_policy_export.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getEnforcerPolicyExport();
				});
			},
			getEnforcerPolicyExport: function () {
			},
			//
			loadEnforcerKeyList: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/enforcer_key_list.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getEnforcerKeyList();
				});
			},
			getEnforcerKeyList: function () {
				window.lim.getJSON('/opendnssec/enforcer_key_list', {
					verbose: true
				})
				.done(function (data) {
		    		if (data.zone && data.zone.length) {
		    			$('#opendnssec-content table tbody').empty();
		    			
			    		data.zone.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.zone, function () {
			    			if (this.key && this.key.length) {
				    			var name = this.name;
			    				$.each(this.key, function () {
					    			$('#opendnssec-content table tbody').append(
					    				$('<tr></tr>')
					    				.append(
					    					$('<td></td>').text(name),
					    					$('<td></td>').text(this.type),
					    					$('<td></td>').text(this.state),
					    					$('<td></td>').text(this.next_transaction),
					    					$('<td></td>').text(this.cka_id),
					    					$('<td></td>').text(this.repository),
					    					$('<td></td>').text(this.keytag)
				    					));
			    				});
			    			}
			    			else if (this.key && this.key.type) {
				    			$('#opendnssec-content table tbody').append(
				    				$('<tr></tr>')
				    				.append(
				    					$('<td></td>').text(this.name),
				    					$('<td></td>').text(this.key.type),
				    					$('<td></td>').text(this.key.state),
				    					$('<td></td>').text(this.key.next_transaction),
				    					$('<td></td>').text(this.key.cka_id),
				    					$('<td></td>').text(this.key.repository),
				    					$('<td></td>').text(this.key.keytag)
			    					));
			    			}
			    		});
			    		return;
		    		}
		    		else if (data.zone && data.zone.name) {
		    			$('#opendnssec-content table tbody').empty();

		    			if (data.zone.key && data.zone.key.length) {
			    			var name = this.name;
		    				$.each(this.key, function () {
				    			$('#opendnssec-content table tbody').append(
				    				$('<tr></tr>')
				    				.append(
				    					$('<td></td>').text(name),
				    					$('<td></td>').text(this.type),
				    					$('<td></td>').text(this.state),
				    					$('<td></td>').text(this.next_transaction),
				    					$('<td></td>').text(this.cka_id),
				    					$('<td></td>').text(this.repository),
				    					$('<td></td>').text(this.keytag)
			    					));
		    				});
		    			}
		    			else if (data.zone.key && data.zone.key.type) {
			    			$('#opendnssec-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(data.zone.name),
			    					$('<td></td>').text(data.zone.key.type),
			    					$('<td></td>').text(data.zone.key.state),
			    					$('<td></td>').text(data.zone.key.next_transaction),
			    					$('<td></td>').text(data.zone.key.cka_id),
			    					$('<td></td>').text(data.zone.key.repository),
			    					$('<td></td>').text(data.zone.key.keytag)
		    					));
		    			}
		    			return;
		    		}
		    		
		    		$('#opendnssec-content table td i').text('No keys found');
				})
				.fail(function (jqXHR) {
					$('#opendnssec-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read key list: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			loadEnforcerBackupList: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/enforcer_backup_list.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getEnforcerBackupList();
				});
			},
			getEnforcerBackupList: function () {
				window.lim.getJSON('/opendnssec/enforcer_backup_list')
				.done(function (data) {
		    		if (data.repository && data.repository.length) {
		    			$('#opendnssec-content table tbody').empty();
		    			
			    		data.repository.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.repository, function () {
			    			$('#opendnssec-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.unbacked_up_keys)
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.repository && data.repository.name) {
		    			$('#opendnssec-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.repository.name),
		    					$('<td></td>').text(data.repository.unbacked_up_keys)
	    					));
		    			return;
		    		}
		    		
		    		$('#opendnssec-content table td i').text('No backup list found');
				})
				.fail(function (jqXHR) {
					$('#opendnssec-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read backup list: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			loadEnforcerRolloverList: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/enforcer_rollover_list.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getEnforcerRolloverList();
				});
			},
			getEnforcerRolloverList: function () {
				window.lim.getJSON('/opendnssec/enforcer_rollover_list')
				.done(function (data) {
		    		if (data.zone && data.zone.length) {
		    			$('#opendnssec-content table tbody').empty();
		    			
			    		data.zone.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.zone, function () {
			    			$('#opendnssec-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.keytype),
			    					$('<td></td>').text(this.rollover_expected)
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.zone && data.zone.name) {
		    			$('#opendnssec-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.zone.name),
		    					$('<td></td>').text(data.zone.keytype),
		    					$('<td></td>').text(data.zone.rollover_expected)
	    					));
		    			return;
		    		}
		    		
		    		$('#opendnssec-content table td i').text('No rollovers found');
				})
				.fail(function (jqXHR) {
					$('#opendnssec-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read rollover list: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			loadEnforcerUpdate: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/enforcer_update.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getEnforcerUpdate();
				});
			},
			getEnforcerUpdate: function () {
			},
			//
			// SIGNER
			//
			loadSignerZones: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/signer_zones.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getSignerZones();
				});
			},
			getSignerZones: function () {
				window.lim.getJSON('/opendnssec/signer_zones')
				.done(function (data) {
		    		if (data.zone && data.zone.length) {
		    			$('#opendnssec-content table tbody').empty();
		    			
			    		data.zone.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.zone, function () {
			    			$('#opendnssec-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name)
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.zone && data.zone.name) {
		    			$('#opendnssec-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.zone.name)
	    					));
		    			return;
		    		}
		    		
		    		$('#opendnssec-content table td i').text('No zones found');
				})
				.fail(function (jqXHR) {
					$('#opendnssec-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read zones: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
			//
			loadSignerSign: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/signer_sign.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getSignerSign();
				});
			},
			getSignerSign: function () {
			},
			//
			loadSignerClear: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/signer_clear.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getSignerClear();
				});
			},
			getSignerClear: function () {
			},
			//
			loadSignerQueue: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/signer_queue.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getSignerQueue();
				});
			},
			getSignerQueue: function () {
			},
			//
			loadSignerFlush: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/signer_flush.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getSignerFlush();
				});
			},
			getSignerFlush: function () {
			},
			//
			loadSignerUpdate: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/signer_update.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getSignerUpdate();
				});
			},
			getSignerUpdate: function () {
			},
			//
			// HSM
			//
			loadHsmInfo: function () {
				var that = this;
				window.lim.loadPage('/_opendnssec/hsm_info.html')
				.done(function (data) {
					window.lim.display(data, '#opendnssec-content');
					that.getHsmInfo();
				});
			},
			getHsmInfo: function () {
				window.lim.getJSON('/opendnssec/hsm_info')
				.done(function (data) {
		    		if (data.repository && data.repository.length) {
		    			$('#opendnssec-content table tbody').empty();
		    			
			    		data.repository.sort(function (a, b) {
			    			return (a.name > b.name) ? 1 : ((a.name < b.name) ? -1 : 0);
			    		});

			    		$.each(data.repository, function () {
			    			$('#opendnssec-content table tbody').append(
			    				$('<tr></tr>')
			    				.append(
			    					$('<td></td>').text(this.name),
			    					$('<td></td>').text(this.manufacturer),
			    					$('<td></td>').text(this.model),
			    					$('<td></td>').text(this.token_label),
			    					$('<td></td>').text(this.slot),
			    					$('<td></td>').text(this.serial),
			    					$('<td></td>').text(this.module)
		    					));
			    		});
			    		return;
		    		}
		    		else if (data.repository && data.repository.name) {
		    			$('#opendnssec-content table tbody')
		    			.empty()
		    			.append(
		    				$('<tr></tr>')
		    				.append(
		    					$('<td></td>').text(data.repository.name),
		    					$('<td></td>').text(data.repository.manufacturer),
		    					$('<td></td>').text(data.repository.model),
		    					$('<td></td>').text(data.repository.token_label),
		    					$('<td></td>').text(data.repository.slot),
		    					$('<td></td>').text(data.repository.serial),
		    					$('<td></td>').text(data.repository.module)
	    					));
		    			return;
		    		}
		    		
		    		$('#opendnssec-content table td i').text('No zones found');
				})
				.fail(function (jqXHR) {
					$('#opendnssec-content')
					.empty()
					.append(
						$('<p class="text-error"></p>')
						.text('Unable to read zones: '+window.lim.getXHRError(jqXHR))
						);
				});
			},
		};
		window.lim.module.opendnssec.init();
	});
})(window.jQuery);
