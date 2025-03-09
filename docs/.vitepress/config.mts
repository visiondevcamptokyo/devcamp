import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "DevCamp",
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
  ],
  description: "VisionDevCamp's Digital Gathering Spaces",
  locales: {
    root: {
      label: 'English',
      lang: 'en',
      link: '/',
      themeConfig: {
        // https://vitepress.dev/reference/default-theme-config
        nav: [
          { text: 'Home', link: '/' },
          // { text: 'Examples', link: '/markdown-examples' },
          { text: 'TestFlight', link: 'https://testflight.apple.com/join/UrHNxNPR' }
        ],
    
        sidebar: [
          {
            text: 'Introduction',
            items: [
              { text: 'What is DevCamp?', link: '/what-is-devcamp' },
              { text: 'Get Started', link: '/get-started' }
            ]
          },
          // {
          //   text: 'Core Concepts',
          //   items: [
          //     { text: 'FaceTime and Spatial Persona', link: '/markdown-examples' },
          //     { text: 'Nostr protocol', link: '/api-examples' }
          //   ]
          // }
        ],
    
        socialLinks: [
          { icon: 'github', link: 'https://github.com/visiondevcamptokyo/devcamp' }
        ]
      }
    },
    ja: {
      label: 'Japanese',
      lang: 'ja',
      link: '/ja/',
      themeConfig: {
        // https://vitepress.dev/reference/default-theme-config
        nav: [
          { text: 'Home', link: '/' },
          // { text: 'Examples', link: '/markdown-examples' },
          { text: 'TestFlight', link: 'https://testflight.apple.com/join/UrHNxNPR' }
        ],
    
        sidebar: [
          {
            text: 'Introduction',
            items: [
              { text: 'DevCampとは?', link: '/ja/what-is-devcamp' },
              { text: '始める', link: '/ja/get-started' }
            ]
          },
          // {
          //   text: 'Core Concepts',
          //   items: [
          //     { text: 'FaceTime and Spatial Persona', link: '/markdown-examples' },
          //     { text: 'Nostr protocol', link: '/api-examples' }
          //   ]
          // }
        ],
    
        socialLinks: [
          { icon: 'github', link: 'https://github.com/visiondevcamptokyo/devcamp' }
        ]
      }
    }
  },
})
