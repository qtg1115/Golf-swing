--!strict
-- 게임 전반에서 공유하는 설정값 모음.
-- 서버(코스 생성/판정)와 클라이언트(입력/조준)가 같은 값을 참조합니다.

export type CourseConfig = {
	Width: number,
	Length: number,
	GroundThickness: number,
}

export type HoleConfig = {
	Position: Vector3,
	Radius: number,
	CaptureSpeed: number,
}

export type BallConfig = {
	Radius: number,
	StartHeight: number,
	ResetY: number,
	StopSpeed: number,
}

export type SwingConfig = {
	MinPower: number,
	MaxPower: number,
	ChargeTime: number,
	LaunchAngle: number,
}

export type ConfigType = {
	Course: CourseConfig,
	TeeGround: Vector3,
	Hole: HoleConfig,
	Ball: BallConfig,
	Swing: SwingConfig,
}

local Config: ConfigType = {
	-- 코스(잔디 바닥) 크기. Length는 티~홀 방향(Z축) 길이입니다.
	Course = {
		Width = 60,
		Length = 200,
		GroundThickness = 2,
	},

	-- 공이 놓이는 티(출발) 지점의 지면 좌표.
	TeeGround = Vector3.new(0, 0, -80),

	-- 홀(구멍) 설정.
	Hole = {
		Position = Vector3.new(0, 0, 80),
		Radius = 4,
		-- 이 속도보다 느릴 때만 홀에 빠진 것으로 인정합니다.
		CaptureSpeed = 26,
	},

	-- 골프공 설정.
	Ball = {
		Radius = 1,
		StartHeight = 3,
		-- 공이 코스 밖으로 떨어지면(이 Y값 아래) 티로 되돌립니다.
		ResetY = -40,
		-- 이 속도 미만이면 "멈춤"으로 보고 다시 칠 수 있습니다.
		StopSpeed = 4,
	},

	-- 스윙(파워 차징) 설정.
	Swing = {
		MinPower = 45,
		MaxPower = 280,
		-- 최대 파워까지 차오르는 데 걸리는 시간(초).
		ChargeTime = 1.4,
		-- 공을 띄우는 각도(도).
		LaunchAngle = 20,
	},
}

return Config
