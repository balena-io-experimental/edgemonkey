import * as express from 'express';
import * as bodyParser from 'body-parser';
import * as http from 'http';
import * as morgan from 'morgan';
import { child_process, fs } from 'mz';

import { version } from './version';
import { Actions } from './actions';
import { randomActions } from './random';
import { port, loopTimeMs } from './config';

const app = express();

app.disable('x-powered-by');
app.use((req, res, next) => {
	res.header('Access-Control-Allow-Origin', req.get('Origin') || '*');
	res.header('Access-Control-Allow-Methods', 'GET, POST');
	res.header(
		'Access-Control-Allow-Headers',
		'Content-Type, Authorization, Application-Record-Count, MaxDataServiceVersion, X-Requested-With',
	);
	res.header('Access-Control-Allow-Credentials', 'true');

	next();
});

app.options('*', (_req, res) => res.sendStatus(200));
app.get('/ping', (_req, res) => res.send('OK'));

app.post('/v1/random', async (_req, res) => {
	randomActions(loopTimeMs, port);
	return res.sendStatus(201);
});

app.post('/v1/:action', async (_req, res) => {
	const action = _req.params.action.toLowerCase();
	if (!(action in Actions)) {
		console.log(`didn't find ${action}`);
		return res.status(404).json({ error: 'no command found' });
	}
	console.log(`running ${action}..`);
	const [stdout] = await child_process.exec(`source ./actions.sh && ${action}`);
	return res.status(200).json({ stdout });
});

// app.use('/metrics', metrics.requestHandler());
app.use(bodyParser.json());
app.use(
	morgan(
		(tokens, req, res) => {
			const date = new Date().toISOString();
			const url = req.url;
			const statusCode = tokens.status(req, res) || '-';
			const responseTime = tokens['response-time'](req, res) || '-';
			const userAgent = req.headers['user-agent'] || '-';

			return `${date} ${tokens['remote-addr'](req, res)} ${
				req.method
			} ${url} ${statusCode} ${responseTime}ms ${userAgent}`;
		},
		{
			skip: (req) => req.url === '/ping',
		},
	),
);

http
	.createServer(app)
	.listen(port, () =>
		console.log(`Edgemonkey API v${version} listening on port ${port}`),
	);
