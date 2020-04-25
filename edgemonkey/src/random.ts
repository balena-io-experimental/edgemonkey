import { DestroyActions } from './actions';
import { lambdaValue, filterValue, timeSlices } from './config';
import * as _ from 'lodash';
import * as random from 'random';
import axios from 'axios';

const delay = (ms: number) => {
	return new Promise((resolve) => setTimeout(resolve, ms));
};

export const randomActions = async (
	loopTimeMs: number,
	port: number,
): Promise<undefined> => {
	// start random destruction
	// let's use a poisson process to simulate actual real world events
	// reset every $RESET minutes using cleanup
	const startTime = new Date().getTime();
	let now = new Date().getTime();
	const poisson = random.poisson(lambdaValue);
	let action;
	let trigger;
	let output;
	while (now - startTime < loopTimeMs) {
		trigger = poisson();
		console.debug(`trigger ${trigger}`);
		if (trigger >= filterValue) {
			action = _.sample(Object.values(DestroyActions)) as DestroyActions;
			console.log(`running ${action}`);
			output = await axios.post(`http://localhost:${port}/v1/${action}`);
			console.log(`output: ${output.data.stdout}`);
		}
		await delay(loopTimeMs / timeSlices);
		now = new Date().getTime();
	}
	console.log(`cleaning up`);
	await axios.post(`http://localhost:${port}/v1/cleanup`);
	return;
};
