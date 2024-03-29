from django.contrib import admin
import logging

logger = logging.getLogger(__name__)


class MyAdminSite(admin.AdminSite):

    def get_app_list(self, request):
        """
        Return a sorted list of all the installed apps that have been
        registered in this site.
        """
        ordering = {
            'auth': 0,
            # 'django_rest_multitokenauth': 1,
            'ddosdb': 1,
            'django_celery_beat': 2,
            'django_celery_results': 3,
        }

        app_dict = self._build_app_dict(request)
        # if 'django_rest_multitokenauth' in app_dict:
        #     del app_dict['django_rest_multitokenauth']

        app_list = sorted(app_dict.values(), key=lambda x: x['name'].lower())

        for app in app_list:
            # Simply add apps not named above to the end of the line
            if not app['app_label'] in ordering:
                ordering[app['app_label']] = len(ordering)
            # Change name for specific app(s)

        app_list = sorted(app_dict.values(), key=lambda x: ordering[x['app_label']])

        celery_order = {
            'Periodic tasks': 0,
            'Intervals': 1,
            'Solar events': 2,
            'Crontabs': 3,
            'Clocked': 4,
        }

        # Sort the models reverse alphabetically within each app.
        for app in app_list:
            if app['app_label'] == 'django_celery_beat':
                app['models'].sort(key=lambda x: celery_order[x['name']])
            else:
                app['models'].sort(key=lambda x: x['name'].lower(), reverse=True)

        return app_list

