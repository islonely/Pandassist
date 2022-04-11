module main

import nedpals.vex.html

const(
	header_html = html.Tag{
		name: 'nav'
		attr: {
			'class': 'bg-white border-gray-200 px-2 sm:px-4 py-2.5 rounded'
		}
		children: [
			html.Tag{
				name: 'div'
				attr: {
					'class': 'container flex flex-wrap justify between items-center mx-auto'
				}
				children: [
					html.Tag{
						name: 'a'
						attr: {
							'class': 'flex items-center'
							'href': '#'
						}
						children: [
							html.Tag{
								name: 'img'
								attr: {
									'src': ''
									'class': 'mr-3 h-6 sm:h-9'
									'alt': 'Pandassist Logo'
								}
							},
							html.Tag{
								name: 'span'
								attr: {
									'class': 'self-center text-x1 font-semibold whitespace-nowrap'
								}
							}
						]
					},
					html.Tag{
						name: 'button'
						attr: {
							'data-collapse-toggle': 'mobile-menu'
							'class': 'inline-flex items-center p-2 m1-3 text-sm text-gray-500 rounded-lg md: hidden hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200'
							'aria-controls': 'mobile menu'
							'aria expanded': 'false'
						}
					}
				]
			}
		]
	}
)