export const port =
	((process.env.EDGEMONKEY_PORT as unknown) as number) ?? 9000;
export const loopTimeMs =
	((process.env.LOOP_TIME_MS as unknown) as number) ?? 60000;
export const lambdaValue =
	((process.env.LAMBDA_VALUE as unknown) as number) ?? 4;
export const filterValue =
	((process.env.FILTER_VALUE as unknown) as number) ?? 5;
export const timeSlices =
	((process.env.TIME_SLICES as unknown) as number) ?? 20;
